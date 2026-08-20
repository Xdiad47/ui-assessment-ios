import Foundation

/// Caps the "Important Notice" gov-disclaimer popup at 3 shows TOTAL per service, within 7
/// days of the first time it was ever shown for that service — then it stops permanently
/// (not a recurring reset) until the app is reinstalled, since a fresh install starts with
/// empty UserDefaults. Mirrors PreferenceManager.shouldShowGovDisclaimer/
/// recordGovDisclaimerShown on Android so both platforms enforce the exact same policy. Each
/// service (passport, visa, rto, my_orders, ...) is tracked independently.
///
/// Uses new key names rather than the old daily-count keys this replaced, so a device that
/// already had "shown 3 times today" stored under the old scheme can't be misread as "shown
/// 3 times ever" under the new one.
final class GovDisclaimerFrequencyStore {
    static let shared = GovDisclaimerFrequencyStore()
    private init() {}

    private let maxShowsTotal = 3
    private let windowDays = 7
    private let dayMillis: TimeInterval = 24 * 60 * 60
    private let defaults = UserDefaults.standard

    private func firstShownKey(_ serviceKey: String) -> String { "com.itzeazy.disclaimer.\(serviceKey).firstShownAt" }
    private func countKey(_ serviceKey: String) -> String { "com.itzeazy.disclaimer.\(serviceKey).totalCount" }

    /// True while this service's lifetime show-count is still under the cap AND still within
    /// the 7-day window from the first time it was shown (or it's never been shown yet).
    func shouldShow(_ serviceKey: String) -> Bool {
        guard defaults.integer(forKey: countKey(serviceKey)) < maxShowsTotal else { return false }
        let firstShownAt = defaults.double(forKey: firstShownKey(serviceKey))
        guard firstShownAt > 0 else { return true } // never shown yet for this service
        let daysSinceFirstShown = (Date().timeIntervalSince1970 - firstShownAt) / dayMillis
        return daysSinceFirstShown < Double(windowDays)
    }

    /// Call exactly once per screen entry where the popup is actually presented.
    func recordShown(_ serviceKey: String) {
        let key = firstShownKey(serviceKey)
        if defaults.double(forKey: key) == 0 {
            defaults.set(Date().timeIntervalSince1970, forKey: key)
        }
        let countK = countKey(serviceKey)
        defaults.set(defaults.integer(forKey: countK) + 1, forKey: countK)
    }
}
