import HealthKit
import Observation

@Observable
final class HealthManager {
    private(set) var realKm: Double = 0.0
    var testKmOffset: Double = 0.0

    var todayKm: Double { realKm + testKmOffset }

    var isAuthorized = false

    private let store = HKHealthStore()
    private let distanceType = HKQuantityType(.distanceWalkingRunning)

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
            let meters = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            DispatchQueue.main.async {
                self?.realKm = meters / 1000.0
            }
        }

        store.execute(query)
    }

    /// Adds 1 km for testing purposes
    func addTestKm() {
        testKmOffset += 1.0
    }

    /// Resets the km counter (called when companion is restarted)
    func resetKm() {
        testKmOffset = 0
        realKm = 0
    }

    /// Fetch km for a specific calendar day (async)
    func fetchKm(for date: Date) async -> Double {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let meters = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                continuation.resume(returning: meters / 1000.0)
            }
            store.execute(query)
        }
    }
}
