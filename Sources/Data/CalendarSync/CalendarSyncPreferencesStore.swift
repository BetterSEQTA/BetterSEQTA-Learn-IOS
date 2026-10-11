import Domain
import Foundation

struct CalendarSyncPreferencesStore {
    private let defaults: UserDefaults
    private let preferencesKey = "learn.calendarSync.preferences"
    private let timetableEventIDsKey = "learn.calendarSync.timetableEventIDs"
    private let assessmentEventIDsKey = "learn.calendarSync.assessmentEventIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPreferences() -> CalendarSyncPreferences {
        guard let data = defaults.data(forKey: preferencesKey),
              let decoded = try? JSONDecoder().decode(CalendarSyncPreferences.self, from: data) else {
            return CalendarSyncPreferences()
        }
        return decoded
    }

    func savePreferences(_ preferences: CalendarSyncPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: preferencesKey)
    }

    func loadTimetableEventIDs() -> [String: String] {
        loadStringMap(forKey: timetableEventIDsKey)
    }

    func saveTimetableEventIDs(_ map: [String: String]) {
        saveStringMap(map, forKey: timetableEventIDsKey)
    }

    func loadAssessmentEventIDs() -> [String: String] {
        loadStringMap(forKey: assessmentEventIDsKey)
    }

    func saveAssessmentEventIDs(_ map: [String: String]) {
        saveStringMap(map, forKey: assessmentEventIDsKey)
    }

    private func loadStringMap(forKey key: String) -> [String: String] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveStringMap(_ map: [String: String], forKey key: String) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: key)
    }
}
