import CoreLocation
import CoreMotion
import Observation

enum RunState { case idle, running, paused, finished }

@Observable
final class RunTracker: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let pedometer = CMPedometer()
    private var lastLocation: CLLocation?
    private var timer: Timer?
    private var notMovingSeconds: Int = 0
    private var hasMovedSinceStart: Bool = false

    var state: RunState = .idle
    var distanceKm: Double = 0
    var elapsedSeconds: Int = 0
    var isMoving: Bool = false
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    var routeCoordinates: [CLLocationCoordinate2D] = []

    // Settings
    var isIndoor: Bool = false
    var isAutoPause: Bool = false
    var autoPauseTriggered: Bool = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        locationAuthStatus = locationManager.authorizationStatus
    }

    // MARK: - Controls

    func requestPermissionAndStart() {
        if isIndoor { start(); return }
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            start()
        }
    }

    var needsMotionPermission: Bool {
        CMMotionActivityManager.authorizationStatus() == .notDetermined
    }

    func requestLocationPermission() {
        guard locationManager.authorizationStatus == .notDetermined else { return }
        locationManager.requestWhenInUseAuthorization()
    }

    /// Triggers the CoreMotion system permission dialog by starting a brief activity query.
    func requestMotionPermission(completion: @escaping (Bool) -> Void) {
        let manager = CMMotionActivityManager()
        manager.startActivityUpdates(to: .main) { _ in }
        // The dialog is asynchronous — poll after a short delay for the result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            manager.stopActivityUpdates()
            completion(CMMotionActivityManager.authorizationStatus() == .authorized)
        }
    }

    func start() {
        guard state == .idle || state == .paused else { return }
        hasMovedSinceStart = false
        notMovingSeconds = 0
        if isIndoor {
            startPedometer()
        } else {
            locationManager.startUpdatingLocation()
        }
        state = .running
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        if isIndoor { pedometer.stopUpdates() } else { locationManager.stopUpdatingLocation() }
        lastLocation = nil
        notMovingSeconds = 0
        state = .paused
        stopTimer()
        isMoving = false
    }

    func resume() {
        guard state == .paused else { return }
        autoPauseTriggered = false
        if isIndoor {
            startPedometer()
        } else {
            locationManager.startUpdatingLocation()
        }
        state = .running
        startTimer()
    }

    func finish() {
        if isIndoor { pedometer.stopUpdates() } else { locationManager.stopUpdatingLocation() }
        stopTimer()
        state = .finished
        isMoving = false
        lastLocation = nil
        notMovingSeconds = 0
    }

    func reset() {
        distanceKm = 0
        elapsedSeconds = 0
        isMoving = false
        lastLocation = nil
        routeCoordinates = []
        notMovingSeconds = 0
        autoPauseTriggered = false
        state = .idle
    }

    // MARK: - Indoor (pedometer)

    private func startPedometer() {
        guard CMPedometer.isDistanceAvailable() else { return }
        let baseline = distanceKm   // preserve km from previous segments (e.g. after resume)
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self, let data, error == nil, state == .running else { return }
            let meters = data.distance?.doubleValue ?? 0
            DispatchQueue.main.async {
                self.distanceKm = baseline + meters / 1000.0
                self.isMoving = (data.currentPace?.doubleValue ?? 999) < 20
                if self.isMoving { self.hasMovedSinceStart = true }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsedSeconds += 1
            if isAutoPause && state == .running && hasMovedSinceStart {
                if !isMoving {
                    notMovingSeconds += 1
                    if notMovingSeconds >= 3 {
                        autoPauseTriggered = true
                        notMovingSeconds = 0
                    }
                } else {
                    notMovingSeconds = 0
                }
            }
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
        if isMoving { hasMovedSinceStart = true }

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
