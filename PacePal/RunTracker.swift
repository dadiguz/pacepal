import CoreLocation
import Observation

enum RunState { case idle, running, paused, finished }

@Observable
final class RunTracker: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var timer: Timer?

    var state: RunState = .idle
    var distanceKm: Double = 0
    var elapsedSeconds: Int = 0
    var isMoving: Bool = false
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    var routeCoordinates: [CLLocationCoordinate2D] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        locationAuthStatus = locationManager.authorizationStatus
    }

    // MARK: - Controls

    func requestPermissionAndStart() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            start()
        }
    }

    func start() {
        guard state == .idle || state == .paused else { return }
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
        state = .finished
        isMoving = false
        lastLocation = nil
    }

    func reset() {
        distanceKm = 0
        elapsedSeconds = 0
        isMoving = false
        lastLocation = nil
        routeCoordinates = []
        state = .idle
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Formatted time

    var formattedTime: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    /// Pace in min/km — returns nil until enough distance has been covered
    var formattedPace: String? {
        guard distanceKm >= 0.05 else { return nil }
        let paceSeconds = Double(elapsedSeconds) / distanceKm
        let paceMin = Int(paceSeconds) / 60
        let paceSec = Int(paceSeconds) % 60
        return String(format: "%d:%02d", paceMin, paceSec)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state == .running, let location = locations.last else { return }
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 50 else { return }

        isMoving = location.speed > 0.5

        if let last = lastLocation {
            let delta = location.distance(from: last) / 1000.0
            if delta < 0.1 { distanceKm += delta }
        }
        lastLocation = location
        routeCoordinates.append(location.coordinate)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            if state == .idle { start() }
        }
    }
}
