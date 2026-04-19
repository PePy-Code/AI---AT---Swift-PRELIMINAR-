import Foundation

public struct AppPreferenceValues: Sendable, Equatable {
    public var timerSoundSystemID: Int?
    public var notificationsEnabled: Bool
    public var mentalTrainerSuggestionEnabled: Bool

    public init(
        timerSoundSystemID: Int? = 1005,
        notificationsEnabled: Bool = true,
        mentalTrainerSuggestionEnabled: Bool = true
    ) {
        self.timerSoundSystemID = timerSoundSystemID
        self.notificationsEnabled = notificationsEnabled
        self.mentalTrainerSuggestionEnabled = mentalTrainerSuggestionEnabled
    }
}

public struct AppPreferenceStore: Sendable {
    private enum Keys {
        static let timerSoundSystemID = "app-settings.timer-sound-system-id"
        static let notificationsEnabled = "app-settings.notifications-enabled"
        static let mentalTrainerSuggestionEnabled = "app-settings.mental-trainer-suggestion-enabled"
    }

    public static let defaultTimerSoundSystemID = 1005
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func values() -> AppPreferenceValues {
        AppPreferenceValues(
            timerSoundSystemID: timerSoundSystemID,
            notificationsEnabled: notificationsEnabled,
            mentalTrainerSuggestionEnabled: mentalTrainerSuggestionEnabled
        )
    }

    public var timerSoundSystemID: Int? {
        get {
            if defaults.object(forKey: Keys.timerSoundSystemID) == nil {
                return Self.defaultTimerSoundSystemID
            }
            let value = defaults.integer(forKey: Keys.timerSoundSystemID)
            return value <= 0 ? nil : value
        }
        nonmutating set {
            let value = newValue ?? 0
            defaults.set(value, forKey: Keys.timerSoundSystemID)
        }
    }

    public var notificationsEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.notificationsEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.notificationsEnabled)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Keys.notificationsEnabled)
        }
    }

    public var mentalTrainerSuggestionEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.mentalTrainerSuggestionEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.mentalTrainerSuggestionEnabled)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Keys.mentalTrainerSuggestionEnabled)
        }
    }
}

public enum AppPreferences {
    private static let store = AppPreferenceStore()

    public static func values() -> AppPreferenceValues {
        store.values()
    }

    public static var timerSoundSystemID: Int? {
        get { store.timerSoundSystemID }
        set { store.timerSoundSystemID = newValue }
    }

    public static var notificationsEnabled: Bool {
        get { store.notificationsEnabled }
        set { store.notificationsEnabled = newValue }
    }

    public static var mentalTrainerSuggestionEnabled: Bool {
        get { store.mentalTrainerSuggestionEnabled }
        set { store.mentalTrainerSuggestionEnabled = newValue }
    }
}
