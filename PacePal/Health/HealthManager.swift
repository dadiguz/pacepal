import HealthKit
import Observation

@Observable
final class HealthManager {
    private(set) var realKm: Double = 0.0
    var testKmOffset: Double = 0.0
    var todayKm: Double { realKm + testKmOffset }
    var isAuthorized = false

    // Run stats populated by fetchRunStats(since:)
    private(set) var totalRuns: Int = 0
    private(set) var totalKmAllTime: Double = 0.0
    private(set) var bestStreak: Int = 0

    enum AuthState { case idle, requesting, authorized, denied, unavailable }
    var authState: AuthState = .idle

    private let store = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()

    // MARK: - Authorization

    func requestAuthorizationAndFetch() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authState = .unavailable; return
        }
        store.requestAuthorization(toShare: [], read: [workoutType]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.authState = granted ? .authorized : .denied
                if granted { self?.fetchToday() }
            }
        }
    }

    func requestFromPermissionScreen() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authState = .unavailable; return
        }
        authState = .requesting
        store.requestAuthorization(toShare: [], read: [workoutType]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.authState = (granted && error == nil) ? .authorized : .denied
                if granted { self?.fetchToday() }
            }
        }
    }

    // MARK: - Today

    func fetchToday() {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        Task {
            let km = await fetchRunningKm(from: start, to: now)
            await MainActor.run { self.realKm = km }
        }
    }

    // MARK: - Single day (used by HistoryView)

    func fetchKm(for date: Date) async -> Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return await fetchRunningKm(from: start, to: end)
    }

    // MARK: - Aggregate stats (used by PetStatusSheet)

    func fetchRunStats(since startDate: Date) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: startDate)

        // Fetch all running workouts since startDate in a single query
        let workouts = await queryRunningWorkouts(from: start, to: now)

        // Group total distance by calendar day
        var dayKm: [Date: Double] = [:]
        var totalKm = 0.0
        for w in workouts {
            let day = cal.startOfDay(for: w.startDate)
            let meters = w.totalDistance?.doubleValue(for: .meter()) ?? 0
            let km = meters / 1000.0
            dayKm[day, default: 0] += km
            totalKm += km
        }

        // Walk each day to count runs and compute best streak
        var day = start
        let today = cal.startOfDay(for: now)
        var runs = 0, currentStreak = 0, best = 0
        while day <= today {
            if (dayKm[day] ?? 0) >= 0.5 {
                runs += 1
                currentStreak += 1
                best = max(best, currentStreak)
            } else {
                currentStreak = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let finalRuns = runs
        let finalKm   = totalKm
        let finalBest = best
        await MainActor.run {
            self.totalRuns       = finalRuns
            self.totalKmAllTime  = finalKm
            self.bestStreak      = finalBest
        }
    }

    // MARK: - Helpers

    func addTestKm() { testKmOffset += 1.0 }

    func resetKm() { testKmOffset = 0; realKm = 0 }

    // Returns total km from running workouts in the given interval
    private func fetchRunningKm(from start: Date, to end: Date) async -> Double {
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let workouts = await queryRunningWorkouts(from: start, to: end)
        let meters = workouts.reduce(0.0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) }
        return meters / 1000.0
    }

    private func queryRunningWorkouts(from start: Date, to end: Date) async -> [HKWorkout] {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForSamples(withStart: start, end: end),
            HKQuery.predicateForWorkouts(with: .running)
        ])
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }
}
