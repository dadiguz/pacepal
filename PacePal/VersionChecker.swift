import Foundation
import Observation

// MARK: - Remote version config

private struct RemoteVersion: Decodable {
    let minimum: String
    let latest: String
}

// MARK: - VersionChecker

@Observable
final class VersionChecker {
    /// URL of your hosted version.json — update when deploying.
    static let versionURL = "https://pacepal.app/version.json"

    var updateRequired: Bool = false

    init() {
        Task { await check() }
    }

    func check() async {
        guard let url = URL(string: Self.versionURL),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let remote = try? JSONDecoder().decode(RemoteVersion.self, from: data)
        else { return }

        let current = appVersion()
        if semver(current) < semver(remote.minimum) {
            await MainActor.run { updateRequired = true }
        }
    }

    // MARK: - Helpers

    private func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /// Converts "1.2.3" → [1, 2, 3] for easy comparison.
    private func semver(_ v: String) -> [Int] {
        v.split(separator: ".").compactMap { Int($0) }
    }
}

// MARK: - Array comparison (lexicographic, padded to same length)

private func < (lhs: [Int], rhs: [Int]) -> Bool {
    let len = max(lhs.count, rhs.count)
    for i in 0..<len {
        let l = i < lhs.count ? lhs[i] : 0
        let r = i < rhs.count ? rhs[i] : 0
        if l != r { return l < r }
    }
    return false
}
