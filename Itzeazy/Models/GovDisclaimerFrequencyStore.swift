import Foundation

/// Caps the "Important Notice" gov-disclaimer popup at 3 shows/day, per service — mirrors
/// PreferenceManager.shouldShowGovDisclaimer/recordGovDisclaimerShown on Android so both
/// platforms enforce the exact same Google Play compliance policy. The counter resets the
/// next calendar day; each service (passport, visa, rto, ...) is tracked independently.
final class GovDisclaimerFrequencyStore {
    static let shared = GovDisclaimerFrequencyStore()
    private init() {}

    private let maxShowsPerDay = 3
    private let defaults = UserDefaults.standard

    private func dateKey(_ serviceKey: String) -> String { "com.itzeazy.disclaimer.\(serviceKey).date" }
    private func countKey(_ serviceKey: String) -> String { "com.itzeazy.disclaimer.\(serviceKey).count" }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }

    /// True while today's shown-count for this service is still under the cap
    /// (or no count has been recorded yet today).
    func shouldShow(_ serviceKey: String) -> Bool {
        let today = todayString()
        let storedDate = defaults.string(forKey: dateKey(serviceKey))
        let storedCount = defaults.integer(forKey: countKey(serviceKey))
        return storedDate != today || storedCount < maxShowsPerDay
    }

    /// Call exactly once per screen entry where the popup is actually presented.
    func recordShown(_ serviceKey: String) {
        let today = todayString()
        let storedDate = defaults.string(forKey: dateKey(serviceKey))
        let previousCount = storedDate == today ? defaults.integer(forKey: countKey(serviceKey)) : 0
        defaults.set(today, forKey: dateKey(serviceKey))
        defaults.set(previousCount + 1, forKey: countKey(serviceKey))
    }
}
