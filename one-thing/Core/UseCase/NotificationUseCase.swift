import Foundation

/// ローカル通知の予約・取り消し処理を抽象化する。
@MainActor
protocol NotificationScheduling {
    /// 指定時刻に 1 回だけ配信する通知を予約する。
    func schedule(identifier: String, title: String, body: String, date: Date) async throws

    /// 指定した通知予約を取り消す。
    func cancelPendingNotifications(identifiers: [String])
}

/// 現在の設定と今日の Thing の状態に合わせてローカル通知を予約する。
struct NotificationUseCase {
    private enum Identifier {
        static let morning = "one-thing.notification.morning"
        static let evening = "one-thing.notification.evening"
        static let all = [morning, evening]
    }

    private let repository: ThingRepository
    private let notificationScheduler: NotificationScheduling
    private let userDefaults: UserDefaults
    private let dayBoundaryUseCase: DayBoundaryUseCase
    private let calendar: Calendar

    /// Thing の保存先、通知予約先、設定保存先を受け取る。
    init(
        repository: ThingRepository,
        notificationScheduler: NotificationScheduling,
        userDefaults: UserDefaults = .standard,
        dayBoundaryUseCase: DayBoundaryUseCase = DayBoundaryUseCase(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.userDefaults = userDefaults
        self.dayBoundaryUseCase = dayBoundaryUseCase
        self.calendar = calendar
    }

    /// 保存済み設定と今日の進捗から、必要な通知だけを予約し直す。
    func execute(now: Date = Date()) async throws {
        notificationScheduler.cancelPendingNotifications(identifiers: Identifier.all)

        guard userDefaults.bool(forKey: SettingsKeys.receivesNotifications) else {
            return
        }

        let dayBoundaryMinutes = integer(
            forKey: SettingsKeys.dayBoundaryMinutes,
            defaultValue: DayBoundaryUseCase.defaultBoundaryHour * 60
        )
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryMinutes / 60
        )
        let thing = try await repository.fetchThing(on: today)

        if thing == nil {
            try await scheduleMorningNotification(now: now)
        }

        if thing?.status != .done {
            try await scheduleEveningNotification(
                body: eveningNotificationBody(for: thing),
                now: now
            )
        }
    }

    private func scheduleMorningNotification(now: Date) async throws {
        let minutes = integer(
            forKey: SettingsKeys.morningNotificationMinutes,
            defaultValue: 8 * 60
        )
        try await notificationScheduler.schedule(
            identifier: Identifier.morning,
            title: "one-thing",
            body: "おはよう。今日は何をする？",
            date: nextTriggerDate(for: minutes, now: now)
        )
    }

    private func scheduleEveningNotification(body: String, now: Date) async throws {
        let minutes = integer(
            forKey: SettingsKeys.eveningNotificationMinutes,
            defaultValue: 21 * 60
        )
        try await notificationScheduler.schedule(
            identifier: Identifier.evening,
            title: "one-thing",
            body: body,
            date: nextTriggerDate(for: minutes, now: now)
        )
    }

    /// 今日やることの登録状態に合わせた夜通知の本文を返す。
    private func eveningNotificationBody(for thing: Thing?) -> String {
        if thing == nil {
            return "おつかれ。今からでもやること決めてみない？"
        }

        return "おつかれ。今日やること、どうだった？"
    }

    private func nextTriggerDate(for minutes: Int, now: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: now)
        let hour = min(max(minutes / 60, 0), 23)
        let minute = min(max(minutes % 60, 0), 59)
        let todayTrigger = calendar.date(
            byAdding: DateComponents(hour: hour, minute: minute),
            to: startOfDay
        ) ?? now

        if todayTrigger > now {
            return todayTrigger
        }

        return calendar.date(byAdding: .day, value: 1, to: todayTrigger) ?? todayTrigger
    }

    private func integer(forKey key: String, defaultValue: Int) -> Int {
        userDefaults.object(forKey: key) == nil
            ? defaultValue
            : userDefaults.integer(forKey: key)
    }
}
