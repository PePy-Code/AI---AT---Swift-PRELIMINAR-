import Foundation

public struct ScheduledNotification: Sendable, Equatable {
    public let id: String
    public let message: NotificationMessage
    public let scheduledAt: Date

    public init(id: String, message: NotificationMessage, scheduledAt: Date) {
        self.id = id
        self.message = message
        self.scheduledAt = scheduledAt
    }
}

public actor InMemoryNotificationScheduler: NotificationScheduling {
    private var notifications: [ScheduledNotification] = []

    public init() {}

    public func schedule(_ message: NotificationMessage, id: String, on day: Date) async {
        let scheduled = ScheduledNotification(id: id, message: message, scheduledAt: day)
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index] = scheduled
        } else {
            notifications.append(scheduled)
        }
    }

    public func scheduledNotifications() -> [ScheduledNotification] {
        notifications.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    public func latestNotification() -> ScheduledNotification? {
        notifications.max { $0.scheduledAt < $1.scheduledAt }
    }
}

public actor EngagementNotificationService {
    private let scheduler: NotificationScheduling
    private let planner: NotificationPlanner
    private let dateProvider: DateProviding
    private let calendar: Calendar

    public init(
        scheduler: NotificationScheduling,
        planner: NotificationPlanner = NotificationPlanner(),
        dateProvider: DateProviding = SystemDateProvider(),
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.planner = planner
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    @discardableResult
    public func scheduleDailyReminder(for activities: [Activity], on day: Date? = nil) async -> NotificationMessage {
        let targetDay = day ?? dateProvider.now
        let scheduledAt = withHour(8, minute: 0, for: targetDay)
        let message = smartReminderMessage(for: activities) ?? planner.reminderForDay(activities: activities)
        guard shouldScheduleNotification(at: scheduledAt) else { return message }
        await scheduler.schedule(message, id: "daily-reminder-\(dayKey(for: targetDay))", on: scheduledAt)
        return message
    }

    @discardableResult
    public func scheduleMentalTrainingMotivation(on day: Date? = nil, streakDays: Int) async -> NotificationMessage {
        let targetDay = day ?? dateProvider.now
        let scheduledAt = withHour(17, minute: 30, for: targetDay)
        let message = planner.mentalTrainingMotivation(streakDays: streakDays)
        guard shouldScheduleNotification(at: scheduledAt) else { return message }
        await scheduler.schedule(message, id: "mental-motivation-\(dayKey(for: targetDay))", on: scheduledAt)
        return message
    }

    @discardableResult
    public func schedulePomodoroTimerNotification(
        activityTitle: String,
        remainingSeconds: Int,
        now: Date? = nil
    ) async -> NotificationMessage {
        let startedAt = now ?? dateProvider.now
        let clampedSeconds = max(remainingSeconds, 0)
        let endsAt = startedAt.addingTimeInterval(TimeInterval(clampedSeconds))
        let message = planner.pomodoroFinishReminder(activityTitle: activityTitle)
        guard shouldScheduleNotification(at: endsAt) else { return message }
        let activitySlug = sanitize(activityTitle)
        await scheduler.schedule(
            message,
            id: "pomodoro-\(activitySlug)-\(Int(endsAt.timeIntervalSince1970))",
            on: endsAt
        )
        return message
    }

    private func withHour(_ hour: Int, minute: Int, for day: Date) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
    }

    private func dayKey(for day: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let date = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, date)
    }

    private func sanitize(_ title: String) -> String {
        let lower = title.lowercased()
        let allowed = lower.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }
        let slug = String(allowed)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return slug.isEmpty ? "actividad" : slug
    }

    private func shouldScheduleNotification(at date: Date) -> Bool {
        AppPreferences.notificationsEnabled && !AppPreferences.isWithinQuietHours(date: date, calendar: calendar)
    }

    private func smartReminderMessage(for activities: [Activity]) -> NotificationMessage? {
        guard AppPreferences.smartRemindersEnabled else { return nil }
        let allowed = allowedReminderTypes()
        guard let preferred = activities.first(where: { allowed.contains($0.type) }) else { return nil }
        switch preferred.type {
        case .study:
            return NotificationMessage(
                title: "Sesión de estudio sugerida",
                body: "Prioriza una sesión de estudio para \(preferred.topic). Un bloque corto hoy te acerca a tu meta."
            )
        case .task:
            return NotificationMessage(
                title: "Tarea clave del día",
                body: "Empieza por \(preferred.title) y desbloquea el resto de tu agenda con más calma."
            )
        case .other:
            return NotificationMessage(
                title: "Actividad rápida recomendada",
                body: "Dedica unos minutos a \(preferred.title) para mantener el ritmo de tu planificación."
            )
        }
    }

    private func allowedReminderTypes() -> Set<ActivityType> {
        var allowed = Set<ActivityType>()
        if AppPreferences.reminderStudyEnabled { allowed.insert(.study) }
        if AppPreferences.reminderTaskEnabled { allowed.insert(.task) }
        if AppPreferences.reminderOtherEnabled { allowed.insert(.other) }
        if allowed.isEmpty { allowed = Set(ActivityType.allCases) }
        return allowed
    }
}

public enum AppNotifications {
    public static let scheduler = InMemoryNotificationScheduler()
    public static let service = EngagementNotificationService(scheduler: scheduler)
}
