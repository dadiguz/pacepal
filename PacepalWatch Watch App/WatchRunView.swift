import SwiftUI
import CoreLocation
import Observation

// MARK: - Watch Run View
struct WatchRunView: View {
    let onFinish: (Double) -> Void

    @State private var tracker = WatchRunTracker()
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 8) {
            // Distance
            Text(String(format: "%.2f", tracker.distanceKm))
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .foregroundStyle(.orange)
            Text("km")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Time
            Text(tracker.formattedTime)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)

            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(tracker.isMoving ? .green : .gray)
                    .frame(width: 6, height: 6)
                Text(tracker.isMoving ? "Corriendo" : "Parado")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Controls
            HStack(spacing: 12) {
                if tracker.state == .running {
                    Button {
                        tracker.pause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                } else if tracker.state == .paused {
                    Button {
                        tracker.resume()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                Button {
                    showConfirm = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { tracker.start() }
        .onDisappear { tracker.pause() }
        .confirmationDialog("Finalizar carrera?", isPresented: $showConfirm) {
            Button("Guardar \(String(format: "%.2f", tracker.distanceKm)) km") {
                tracker.finish()
                onFinish(tracker.distanceKm)
                dismiss()
            }
            Button("Descartar", role: .destructive) {
                tracker.finish()
                dismiss()
            }
            Button("Continuar", role: .cancel) {}
        }
    }
}

// MARK: - Watch Run Tracker (CoreLocation)
@Observable
final class WatchRunTracker: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var lastLocation: CLLocation?

    enum State { case idle, running, paused }

    var state: State = .idle
    var distanceKm: Double = 0
    var elapsedSeconds: Int = 0
    var isMoving: Bool = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
    }

    func start() {
        guard state == .idle else { return }
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        state = .running
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        locationManager.stopUpdatingLocation()
        lastLocation = nil
        state = .paused
        stopTimer()
        isMoving = false
    }

    func resume() {
        guard state == .paused else { return }
        locationManager.startUpdatingLocation()
        state = .running
        startTimer()
    }

    func finish() {
        locationManager.stopUpdatingLocation()
        stopTimer()
        state = .idle
        isMoving = false
        lastLocation = nil
    }

    var formattedTime: String {
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state == .running, let location = locations.last else { return }
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 50 else { return }
        isMoving = location.speed > 0.5
        if let last = lastLocation {
            let delta = location.distance(from: last) / 1000.0
            if delta < 0.1 { distanceKm += delta }
        }
        lastLocation = location
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            if state == .running { manager.startUpdatingLocation() }
        }
    }
}
