import HealthKit
import Observation

@Observable
final class HealthManager {
    var todayKm: Double = 0.0
    var isAuthorized = false

    private let store = HKHealthStore()
    private let distanceType = HKQuantityType(.distanceWalkingRunning)

    // Call once on launch
    func requestAuthorizationAndFetch() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        store.requestAuthorization(toShare: [], read: [distanceType]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted { self?.fetchToday() }
            }
        }
    }

    func fetchToday() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            let km = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            DispatchQueue.main.async {
                self?.todayKm = km / 1000.0
            }
        }

        store.execute(query)
    }
}
