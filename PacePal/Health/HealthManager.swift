import HealthKit
import Observation

@Observable
final class HealthManager {
    private(set) var realKm: Double = 0.0
    private(set) var sessionKm: Double = 0.0   // accumulated in-app km (persisted per day)
    var testKmOffset: Double = 0.0
    /// Uses max() so a simultaneous Watch recording doesn't double-count an in-app session.
    var todayKm: Double { max(realKm, sessionKm) + testKmOffset }
    var isAuthorized = false

    /// Permanent per-day log of in-app run km. Key = Int(startOfDay.timeIntervalSince1970) as String.
    /// Never cleared between app launches so past in-app runs survive HealthKit-only recalculations.
    private(set) var localRunLog: [String: Double] = [:]
    private static let localRunLogKey = "pacepal.localRunLog"

    init() {
        sessionKm = UserDefaults.standard.double(forKey: HealthManager.sessionKmKey())
        let savedLog = UserDefaults.standard.dictionary(forKey: Self.localRunLogKey) as? [String: Double] ?? [:]
        localRunLog = savedLog
    }

    /// Set from AppState.challengeLevel.runThreshold — synced on launch and level change.
    var runThreshold: Double = 0.5

    // Run stats populated by fetchRunStats(since:)
    private(set) var totalRuns: Int = 0
    private(set) var totalKmAllTime: Double = 0.0
    private(set) var bestStreak: Int = 0
    /// True if today was already counted in totalRuns (HealthKit had a qualifying workout today)
    private(set) var todayCountedInStats: Bool = false

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
        let healthKm = await fetchRunningKm(from: start, to: end)
        let localKm = localRunLog[Self.dayKey(for: date)] ?? 0
        return max(healthKm, localKm)
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
        let today = cal.startOfDay(for: now)
        var dayKm: [Date: Double] = [:]
        var totalKm = 0.0
        for w in workouts {
            let day = cal.startOfDay(for: w.startDate)
            let meters = w.totalDistance?.doubleValue(for: .meter()) ?? 0
            let km = meters / 1000.0
            dayKm[day, default: 0] += km
            totalKm += km
        }

        // Merge in-app run log: for each day, take the max of HealthKit and local km.
        // This ensures runs tracked in-app (never written to HealthKit) are counted.
        for (key, km) in localRunLog {
            guard let ts = Double(key) else { continue }
            let entryDay = cal.startOfDay(for: Date(timeIntervalSince1970: ts))
            guard entryDay >= start && entryDay <= today else { continue }
            let existing = dayKm[entryDay] ?? 0
            if km > existing {
                totalKm += km - existing
                dayKm[entryDay] = km
            }
        }

        // Walk each day to count runs and compute best streak
        var day = start
        var runs = 0, currentStreak = 0, best = 0
        while day <= today {
            if (dayKm[day] ?? 0) >= runThreshold {
                runs += 1
                currentStreak += 1
                best = max(best, currentStreak)
            } else {
                currentStreak = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let finalRuns         = runs
        let finalKm           = totalKm
        let finalBest         = best
        let finalTodayCounted = (dayKm[today] ?? 0) >= runThreshold
        await MainActor.run {
            self.totalRuns            = finalRuns
            self.totalKmAllTime       = finalKm
            self.bestStreak           = finalBest
            self.todayCountedInStats  = finalTodayCounted
        }
    }

    // MARK: - Helpers

    func addTestKm() { testKmOffset += 1.0 }

    /// Credits km from an in-app tracking session. Persisted per day in UserDefaults
    /// so repeated calls accumulate instead of being overwritten by HealthKit fetches.
    /// Also writes to localRunLog so the run survives day rollovers and app restarts.
    func addManualKm(_ km: Double) {
        sessionKm += km
        UserDefaults.standard.set(sessionKm, forKey: HealthManager.sessionKmKey())
        let key = Self.dayKey(for: Date())
        localRunLog[key] = sessionKm
        UserDefaults.standard.set(localRunLog, forKey: Self.localRunLogKey)
    }

    func resetKm() { testKmOffset = 0; realKm = 0 }

    /// Clears the in-app session km for today. Call when switching characters so
    /// the previous character's in-app km doesn't bleed into the new one.
    func resetSession() {
        sessionKm = 0
        UserDefaults.standard.set(0.0, forKey: HealthManager.sessionKmKey())
    }

    private static func sessionKmKey() -> String {
        return "pacepal.sessionKm.\(dayKey(for: Date()))"
    }

    private static func dayKey(for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        return "\(Int(day.timeIntervalSince1970))"
    }

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
