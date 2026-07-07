import Foundation

// On-device cache for the `user/documents/*` list endpoints (cities, countries, etc.).
// These lists barely change, so a fresh network hit is only made once per week per key —
// every other screen open shows the cached list instantly with no network wait.
final class DocumentsListCache {
    static let shared = DocumentsListCache()
    private init() {}

    private let refreshInterval: TimeInterval = 7 * 24 * 60 * 60 // 1 week

    private func dataKey(_ key: String) -> String { "com.itzeazy.documents.\(key)" }
    private func fetchedAtKey(_ key: String) -> String { "com.itzeazy.documents.\(key).fetchedAt" }

    func cachedList(for key: String) -> [String]? {
        UserDefaults.standard.stringArray(forKey: dataKey(key))
    }

    /// True when there's no cache yet, or the cache is a week or older.
    func isStale(for key: String) -> Bool {
        guard let fetchedAt = UserDefaults.standard.object(forKey: fetchedAtKey(key)) as? Date else {
            return true
        }
        return Date().timeIntervalSince(fetchedAt) >= refreshInterval
    }

    func save(_ list: [String], for key: String) {
        UserDefaults.standard.set(list, forKey: dataKey(key))
        UserDefaults.standard.set(Date(), forKey: fetchedAtKey(key))
    }
}
