import Foundation

public enum AppVisualTheme: String, CaseIterable, Sendable, Codable {
    case system
    case light
    case dark
}

public enum AppFontScale: String, CaseIterable, Sendable, Codable {
    case small
    case normal
    case large
    case extraLarge
}

public enum AppLanguage: String, CaseIterable, Sendable, Codable {
    case spanish = "es"
    case english = "en"
}

public struct AppPreferenceValues: Sendable, Equatable, Codable {
    public var timerSoundSystemID: Int?
    public var notificationsEnabled: Bool
    public var mentalTrainerSuggestionEnabled: Bool
    public var visualTheme: AppVisualTheme
    public var fontScale: AppFontScale
    public var highContrastEnabled: Bool
    public var pomodoroWorkMinutes: Int
    public var pomodoroBreakMinutes: Int
    public var pomodoroLongBreakMinutes: Int
    public var pomodoroCyclesBeforeLongBreak: Int
    public var pomodoroAutoStartNextPhase: Bool
    public var quietHoursEnabled: Bool
    public var quietHoursStartHour: Int
    public var quietHoursEndHour: Int
    public var smartRemindersEnabled: Bool
    public var reminderStudyEnabled: Bool
    public var reminderTaskEnabled: Bool
    public var reminderOtherEnabled: Bool
    public var dailyGoalMinutes: Int
    public var dailyGoalActivitiesCompleted: Int
    public var dailyGoalTrainerSessions: Int
    public var aiStoreConversationHistory: Bool
    public var aiChatHistoryLimit: Int
    public var language: AppLanguage
    public var localeIdentifier: String
    public var wellbeingActiveBreakEnabled: Bool
    public var wellbeingHydrationEnabled: Bool
    public var wellbeingEyeRestEnabled: Bool
    public var wellbeingReminderMinutes: Int

    public init(
        timerSoundSystemID: Int? = 1005,
        notificationsEnabled: Bool = true,
        mentalTrainerSuggestionEnabled: Bool = true,
        visualTheme: AppVisualTheme = .system,
        fontScale: AppFontScale = .normal,
        highContrastEnabled: Bool = false,
        pomodoroWorkMinutes: Int = 25,
        pomodoroBreakMinutes: Int = 5,
        pomodoroLongBreakMinutes: Int = 15,
        pomodoroCyclesBeforeLongBreak: Int = 4,
        pomodoroAutoStartNextPhase: Bool = false,
        quietHoursEnabled: Bool = false,
        quietHoursStartHour: Int = 22,
        quietHoursEndHour: Int = 7,
        smartRemindersEnabled: Bool = true,
        reminderStudyEnabled: Bool = true,
        reminderTaskEnabled: Bool = true,
        reminderOtherEnabled: Bool = true,
        dailyGoalMinutes: Int = 90,
        dailyGoalActivitiesCompleted: Int = 3,
        dailyGoalTrainerSessions: Int = 1,
        aiStoreConversationHistory: Bool = true,
        aiChatHistoryLimit: Int = 30,
        language: AppLanguage = .spanish,
        localeIdentifier: String = Locale.current.identifier,
        wellbeingActiveBreakEnabled: Bool = true,
        wellbeingHydrationEnabled: Bool = true,
        wellbeingEyeRestEnabled: Bool = true,
        wellbeingReminderMinutes: Int = 30
    ) {
        self.timerSoundSystemID = timerSoundSystemID
        self.notificationsEnabled = notificationsEnabled
        self.mentalTrainerSuggestionEnabled = mentalTrainerSuggestionEnabled
        self.visualTheme = visualTheme
        self.fontScale = fontScale
        self.highContrastEnabled = highContrastEnabled
        self.pomodoroWorkMinutes = pomodoroWorkMinutes
        self.pomodoroBreakMinutes = pomodoroBreakMinutes
        self.pomodoroLongBreakMinutes = pomodoroLongBreakMinutes
        self.pomodoroCyclesBeforeLongBreak = pomodoroCyclesBeforeLongBreak
        self.pomodoroAutoStartNextPhase = pomodoroAutoStartNextPhase
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStartHour = quietHoursStartHour
        self.quietHoursEndHour = quietHoursEndHour
        self.smartRemindersEnabled = smartRemindersEnabled
        self.reminderStudyEnabled = reminderStudyEnabled
        self.reminderTaskEnabled = reminderTaskEnabled
        self.reminderOtherEnabled = reminderOtherEnabled
        self.dailyGoalMinutes = dailyGoalMinutes
        self.dailyGoalActivitiesCompleted = dailyGoalActivitiesCompleted
        self.dailyGoalTrainerSessions = dailyGoalTrainerSessions
        self.aiStoreConversationHistory = aiStoreConversationHistory
        self.aiChatHistoryLimit = aiChatHistoryLimit
        self.language = language
        self.localeIdentifier = localeIdentifier
        self.wellbeingActiveBreakEnabled = wellbeingActiveBreakEnabled
        self.wellbeingHydrationEnabled = wellbeingHydrationEnabled
        self.wellbeingEyeRestEnabled = wellbeingEyeRestEnabled
        self.wellbeingReminderMinutes = wellbeingReminderMinutes
    }
}

public struct AppPreferenceStore {
    private enum Keys {
        static let timerSoundSystemID = "app-settings.timer-sound-system-id"
        static let notificationsEnabled = "app-settings.notifications-enabled"
        static let mentalTrainerSuggestionEnabled = "app-settings.mental-trainer-suggestion-enabled"
        static let visualTheme = "app-settings.visual-theme"
        static let fontScale = "app-settings.font-scale"
        static let highContrastEnabled = "app-settings.high-contrast-enabled"
        static let pomodoroWorkMinutes = "app-settings.pomodoro-work-minutes"
        static let pomodoroBreakMinutes = "app-settings.pomodoro-break-minutes"
        static let pomodoroLongBreakMinutes = "app-settings.pomodoro-long-break-minutes"
        static let pomodoroCyclesBeforeLongBreak = "app-settings.pomodoro-cycles-before-long-break"
        static let pomodoroAutoStartNextPhase = "app-settings.pomodoro-auto-start-next-phase"
        static let quietHoursEnabled = "app-settings.quiet-hours-enabled"
        static let quietHoursStartHour = "app-settings.quiet-hours-start-hour"
        static let quietHoursEndHour = "app-settings.quiet-hours-end-hour"
        static let smartRemindersEnabled = "app-settings.smart-reminders-enabled"
        static let reminderStudyEnabled = "app-settings.reminder-study-enabled"
        static let reminderTaskEnabled = "app-settings.reminder-task-enabled"
        static let reminderOtherEnabled = "app-settings.reminder-other-enabled"
        static let dailyGoalMinutes = "app-settings.daily-goal-minutes"
        static let dailyGoalActivitiesCompleted = "app-settings.daily-goal-activities-completed"
        static let dailyGoalTrainerSessions = "app-settings.daily-goal-trainer-sessions"
        static let aiStoreConversationHistory = "app-settings.ai-store-conversation-history"
        static let aiChatHistoryLimit = "app-settings.ai-chat-history-limit"
        static let language = "app-settings.language"
        static let localeIdentifier = "app-settings.locale-identifier"
        static let wellbeingActiveBreakEnabled = "app-settings.wellbeing-active-break-enabled"
        static let wellbeingHydrationEnabled = "app-settings.wellbeing-hydration-enabled"
        static let wellbeingEyeRestEnabled = "app-settings.wellbeing-eye-rest-enabled"
        static let wellbeingReminderMinutes = "app-settings.wellbeing-reminder-minutes"
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
            mentalTrainerSuggestionEnabled: mentalTrainerSuggestionEnabled,
            visualTheme: visualTheme,
            fontScale: fontScale,
            highContrastEnabled: highContrastEnabled,
            pomodoroWorkMinutes: pomodoroWorkMinutes,
            pomodoroBreakMinutes: pomodoroBreakMinutes,
            pomodoroLongBreakMinutes: pomodoroLongBreakMinutes,
            pomodoroCyclesBeforeLongBreak: pomodoroCyclesBeforeLongBreak,
            pomodoroAutoStartNextPhase: pomodoroAutoStartNextPhase,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStartHour: quietHoursStartHour,
            quietHoursEndHour: quietHoursEndHour,
            smartRemindersEnabled: smartRemindersEnabled,
            reminderStudyEnabled: reminderStudyEnabled,
            reminderTaskEnabled: reminderTaskEnabled,
            reminderOtherEnabled: reminderOtherEnabled,
            dailyGoalMinutes: dailyGoalMinutes,
            dailyGoalActivitiesCompleted: dailyGoalActivitiesCompleted,
            dailyGoalTrainerSessions: dailyGoalTrainerSessions,
            aiStoreConversationHistory: aiStoreConversationHistory,
            aiChatHistoryLimit: aiChatHistoryLimit,
            language: language,
            localeIdentifier: localeIdentifier,
            wellbeingActiveBreakEnabled: wellbeingActiveBreakEnabled,
            wellbeingHydrationEnabled: wellbeingHydrationEnabled,
            wellbeingEyeRestEnabled: wellbeingEyeRestEnabled,
            wellbeingReminderMinutes: wellbeingReminderMinutes
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
            defaults.set(newValue ?? 0, forKey: Keys.timerSoundSystemID)
        }
    }

    public var notificationsEnabled: Bool {
        get { bool(for: Keys.notificationsEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    public var mentalTrainerSuggestionEnabled: Bool {
        get { bool(for: Keys.mentalTrainerSuggestionEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.mentalTrainerSuggestionEnabled) }
    }

    public var visualTheme: AppVisualTheme {
        get {
            guard let raw = defaults.string(forKey: Keys.visualTheme), let value = AppVisualTheme(rawValue: raw) else { return .system }
            return value
        }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Keys.visualTheme) }
    }

    public var fontScale: AppFontScale {
        get {
            guard let raw = defaults.string(forKey: Keys.fontScale), let value = AppFontScale(rawValue: raw) else { return .normal }
            return value
        }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Keys.fontScale) }
    }

    public var highContrastEnabled: Bool {
        get { bool(for: Keys.highContrastEnabled, default: false) }
        nonmutating set { defaults.set(newValue, forKey: Keys.highContrastEnabled) }
    }

    public var pomodoroWorkMinutes: Int {
        get { clampedInt(for: Keys.pomodoroWorkMinutes, default: 25, min: 1, max: 180) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 180), forKey: Keys.pomodoroWorkMinutes) }
    }

    public var pomodoroBreakMinutes: Int {
        get { clampedInt(for: Keys.pomodoroBreakMinutes, default: 5, min: 1, max: 60) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 60), forKey: Keys.pomodoroBreakMinutes) }
    }

    public var pomodoroLongBreakMinutes: Int {
        get { clampedInt(for: Keys.pomodoroLongBreakMinutes, default: 15, min: 1, max: 90) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 90), forKey: Keys.pomodoroLongBreakMinutes) }
    }

    public var pomodoroCyclesBeforeLongBreak: Int {
        get { clampedInt(for: Keys.pomodoroCyclesBeforeLongBreak, default: 4, min: 1, max: 12) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 12), forKey: Keys.pomodoroCyclesBeforeLongBreak) }
    }

    public var pomodoroAutoStartNextPhase: Bool {
        get { bool(for: Keys.pomodoroAutoStartNextPhase, default: false) }
        nonmutating set { defaults.set(newValue, forKey: Keys.pomodoroAutoStartNextPhase) }
    }

    public var quietHoursEnabled: Bool {
        get { bool(for: Keys.quietHoursEnabled, default: false) }
        nonmutating set { defaults.set(newValue, forKey: Keys.quietHoursEnabled) }
    }

    public var quietHoursStartHour: Int {
        get { clampedInt(for: Keys.quietHoursStartHour, default: 22, min: 0, max: 23) }
        nonmutating set { defaults.set(clamp(newValue, min: 0, max: 23), forKey: Keys.quietHoursStartHour) }
    }

    public var quietHoursEndHour: Int {
        get { clampedInt(for: Keys.quietHoursEndHour, default: 7, min: 0, max: 23) }
        nonmutating set { defaults.set(clamp(newValue, min: 0, max: 23), forKey: Keys.quietHoursEndHour) }
    }

    public var smartRemindersEnabled: Bool {
        get { bool(for: Keys.smartRemindersEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.smartRemindersEnabled) }
    }

    public var reminderStudyEnabled: Bool {
        get { bool(for: Keys.reminderStudyEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.reminderStudyEnabled) }
    }

    public var reminderTaskEnabled: Bool {
        get { bool(for: Keys.reminderTaskEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.reminderTaskEnabled) }
    }

    public var reminderOtherEnabled: Bool {
        get { bool(for: Keys.reminderOtherEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.reminderOtherEnabled) }
    }

    public var dailyGoalMinutes: Int {
        get { clampedInt(for: Keys.dailyGoalMinutes, default: 90, min: 1, max: 720) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 720), forKey: Keys.dailyGoalMinutes) }
    }

    public var dailyGoalActivitiesCompleted: Int {
        get { clampedInt(for: Keys.dailyGoalActivitiesCompleted, default: 3, min: 1, max: 30) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 30), forKey: Keys.dailyGoalActivitiesCompleted) }
    }

    public var dailyGoalTrainerSessions: Int {
        get { clampedInt(for: Keys.dailyGoalTrainerSessions, default: 1, min: 1, max: 20) }
        nonmutating set { defaults.set(clamp(newValue, min: 1, max: 20), forKey: Keys.dailyGoalTrainerSessions) }
    }

    public var aiStoreConversationHistory: Bool {
        get { bool(for: Keys.aiStoreConversationHistory, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.aiStoreConversationHistory) }
    }

    public var aiChatHistoryLimit: Int {
        get { clampedInt(for: Keys.aiChatHistoryLimit, default: 30, min: 4, max: 500) }
        nonmutating set { defaults.set(clamp(newValue, min: 4, max: 500), forKey: Keys.aiChatHistoryLimit) }
    }

    public var language: AppLanguage {
        get {
            guard let raw = defaults.string(forKey: Keys.language), let value = AppLanguage(rawValue: raw) else { return .spanish }
            return value
        }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Keys.language) }
    }

    public var localeIdentifier: String {
        get {
            if let value = defaults.string(forKey: Keys.localeIdentifier), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
            return Locale.current.identifier
        }
        nonmutating set {
            let cleaned = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            defaults.set(cleaned.isEmpty ? Locale.current.identifier : cleaned, forKey: Keys.localeIdentifier)
        }
    }

    public var wellbeingActiveBreakEnabled: Bool {
        get { bool(for: Keys.wellbeingActiveBreakEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.wellbeingActiveBreakEnabled) }
    }

    public var wellbeingHydrationEnabled: Bool {
        get { bool(for: Keys.wellbeingHydrationEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.wellbeingHydrationEnabled) }
    }

    public var wellbeingEyeRestEnabled: Bool {
        get { bool(for: Keys.wellbeingEyeRestEnabled, default: true) }
        nonmutating set { defaults.set(newValue, forKey: Keys.wellbeingEyeRestEnabled) }
    }

    public var wellbeingReminderMinutes: Int {
        get { clampedInt(for: Keys.wellbeingReminderMinutes, default: 30, min: 5, max: 240) }
        nonmutating set { defaults.set(clamp(newValue, min: 5, max: 240), forKey: Keys.wellbeingReminderMinutes) }
    }

    private func bool(for key: String, default value: Bool) -> Bool {
        if defaults.object(forKey: key) == nil { return value }
        return defaults.bool(forKey: key)
    }

    private func clampedInt(for key: String, default value: Int, min: Int, max: Int) -> Int {
        guard defaults.object(forKey: key) != nil else { return value }
        let raw = defaults.integer(forKey: key)
        return clamp(raw, min: min, max: max)
    }

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, value))
    }
}

public enum AppPreferences {
    private static func store() -> AppPreferenceStore { AppPreferenceStore() }

    public static func values() -> AppPreferenceValues { store().values() }

    public static var timerSoundSystemID: Int? {
        get { store().timerSoundSystemID }
        set { store().timerSoundSystemID = newValue }
    }
    public static var notificationsEnabled: Bool {
        get { store().notificationsEnabled }
        set { store().notificationsEnabled = newValue }
    }
    public static var mentalTrainerSuggestionEnabled: Bool {
        get { store().mentalTrainerSuggestionEnabled }
        set { store().mentalTrainerSuggestionEnabled = newValue }
    }
    public static var visualTheme: AppVisualTheme {
        get { store().visualTheme }
        set { store().visualTheme = newValue }
    }
    public static var fontScale: AppFontScale {
        get { store().fontScale }
        set { store().fontScale = newValue }
    }
    public static var highContrastEnabled: Bool {
        get { store().highContrastEnabled }
        set { store().highContrastEnabled = newValue }
    }
    public static var pomodoroWorkMinutes: Int {
        get { store().pomodoroWorkMinutes }
        set { store().pomodoroWorkMinutes = newValue }
    }
    public static var pomodoroBreakMinutes: Int {
        get { store().pomodoroBreakMinutes }
        set { store().pomodoroBreakMinutes = newValue }
    }
    public static var pomodoroLongBreakMinutes: Int {
        get { store().pomodoroLongBreakMinutes }
        set { store().pomodoroLongBreakMinutes = newValue }
    }
    public static var pomodoroCyclesBeforeLongBreak: Int {
        get { store().pomodoroCyclesBeforeLongBreak }
        set { store().pomodoroCyclesBeforeLongBreak = newValue }
    }
    public static var pomodoroAutoStartNextPhase: Bool {
        get { store().pomodoroAutoStartNextPhase }
        set { store().pomodoroAutoStartNextPhase = newValue }
    }
    public static var quietHoursEnabled: Bool {
        get { store().quietHoursEnabled }
        set { store().quietHoursEnabled = newValue }
    }
    public static var quietHoursStartHour: Int {
        get { store().quietHoursStartHour }
        set { store().quietHoursStartHour = newValue }
    }
    public static var quietHoursEndHour: Int {
        get { store().quietHoursEndHour }
        set { store().quietHoursEndHour = newValue }
    }
    public static var smartRemindersEnabled: Bool {
        get { store().smartRemindersEnabled }
        set { store().smartRemindersEnabled = newValue }
    }
    public static var reminderStudyEnabled: Bool {
        get { store().reminderStudyEnabled }
        set { store().reminderStudyEnabled = newValue }
    }
    public static var reminderTaskEnabled: Bool {
        get { store().reminderTaskEnabled }
        set { store().reminderTaskEnabled = newValue }
    }
    public static var reminderOtherEnabled: Bool {
        get { store().reminderOtherEnabled }
        set { store().reminderOtherEnabled = newValue }
    }
    public static var dailyGoalMinutes: Int {
        get { store().dailyGoalMinutes }
        set { store().dailyGoalMinutes = newValue }
    }
    public static var dailyGoalActivitiesCompleted: Int {
        get { store().dailyGoalActivitiesCompleted }
        set { store().dailyGoalActivitiesCompleted = newValue }
    }
    public static var dailyGoalTrainerSessions: Int {
        get { store().dailyGoalTrainerSessions }
        set { store().dailyGoalTrainerSessions = newValue }
    }
    public static var aiStoreConversationHistory: Bool {
        get { store().aiStoreConversationHistory }
        set { store().aiStoreConversationHistory = newValue }
    }
    public static var aiChatHistoryLimit: Int {
        get { store().aiChatHistoryLimit }
        set { store().aiChatHistoryLimit = newValue }
    }
    public static var language: AppLanguage {
        get { store().language }
        set { store().language = newValue }
    }
    public static var localeIdentifier: String {
        get { store().localeIdentifier }
        set { store().localeIdentifier = newValue }
    }
    public static var wellbeingActiveBreakEnabled: Bool {
        get { store().wellbeingActiveBreakEnabled }
        set { store().wellbeingActiveBreakEnabled = newValue }
    }
    public static var wellbeingHydrationEnabled: Bool {
        get { store().wellbeingHydrationEnabled }
        set { store().wellbeingHydrationEnabled = newValue }
    }
    public static var wellbeingEyeRestEnabled: Bool {
        get { store().wellbeingEyeRestEnabled }
        set { store().wellbeingEyeRestEnabled = newValue }
    }
    public static var wellbeingReminderMinutes: Int {
        get { store().wellbeingReminderMinutes }
        set { store().wellbeingReminderMinutes = newValue }
    }

    public static func isWithinQuietHours(date: Date, calendar: Calendar = .current) -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = calendar.component(.hour, from: date)
        let start = max(0, min(23, quietHoursStartHour))
        let end = max(0, min(23, quietHoursEndHour))
        if start == end { return true }
        if start < end {
            return hour >= start && hour < end
        }
        return hour >= start || hour < end
    }
}

public extension Notification.Name {
    static let aiChatHistoryCleared = Notification.Name("app-settings.ai-chat-history-cleared")
}
