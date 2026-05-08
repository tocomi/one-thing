import Foundation
import Observation
import UserNotifications

/// 設定シートの入力状態を保持し、保存操作で永続化と通知予約更新を行う。
@MainActor
@Observable
final class SettingsViewModel {
    var receivesNotifications: Bool
    var morningNotificationMinutes: Int
    var eveningNotificationMinutes: Int
    var dayBoundaryMinutes: Int
    var notificationPermissionDenied = false
    var isSaving = false
    var isRequestingNotificationPermission = false

    private let userDefaults: UserDefaults
    private let notificationCenter: UNUserNotificationCenter
    private let notificationUseCase: NotificationUseCase?
    private let calendar: Calendar

    /// 永続化先と通知許可要求先を受け取る。
    init(
        userDefaults: UserDefaults = .standard,
        notificationCenter: UNUserNotificationCenter = .current(),
        notificationUseCase: NotificationUseCase? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.notificationUseCase = notificationUseCase
        self.calendar = calendar
        let receivesNotifications = userDefaults.bool(forKey: Keys.receivesNotifications)
        self.receivesNotifications = receivesNotifications
        self.morningNotificationMinutes = Self.integer(
            forKey: Keys.morningNotificationMinutes,
            in: userDefaults,
            defaultValue: 8 * 60
        )
        self.eveningNotificationMinutes = Self.integer(
            forKey: Keys.eveningNotificationMinutes,
            in: userDefaults,
            defaultValue: 21 * 60
        )
        self.dayBoundaryMinutes = Self.integer(
            forKey: Keys.dayBoundaryMinutes,
            in: userDefaults,
            defaultValue: DayBoundaryUseCase.defaultBoundaryHour * 60
        )
    }

    /// 通知 Toggle の変更を反映し、ON にしたときはその場で通知許可を求める。
    func setReceivesNotifications(_ isEnabled: Bool) async {
        guard isEnabled else {
            receivesNotifications = false
            notificationPermissionDenied = false
            return
        }

        guard !isRequestingNotificationPermission else { return }
        receivesNotifications = true
        isRequestingNotificationPermission = true
        defer { isRequestingNotificationPermission = false }

        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            receivesNotifications = granted
            notificationPermissionDenied = !granted
        } catch {
            receivesNotifications = false
            notificationPermissionDenied = true
        }
    }

    /// 編集中の設定を UserDefaults に保存し、通知予約を更新する。
    func save() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        userDefaults.set(receivesNotifications, forKey: Keys.receivesNotifications)
        userDefaults.set(morningNotificationMinutes, forKey: Keys.morningNotificationMinutes)
        userDefaults.set(eveningNotificationMinutes, forKey: Keys.eveningNotificationMinutes)
        userDefaults.set(dayBoundaryMinutes, forKey: Keys.dayBoundaryMinutes)
        try? await notificationUseCase?.execute()

        return true
    }

    /// 保存値を DatePicker で扱える Date に変換する。
    func date(from minutes: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: 2000,
            month: 1,
            day: 1,
            hour: minutes / 60,
            minute: minutes % 60
        )
        return components.date ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    /// DatePicker の Date から 0:00 起点の分数を返す。
    func minutes(from date: Date) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return min(max((hour * 60) + minute, 0), (24 * 60) - 1)
    }

    private static func integer(
        forKey key: String,
        in userDefaults: UserDefaults,
        defaultValue: Int
    ) -> Int {
        userDefaults.object(forKey: key) == nil
            ? defaultValue
            : userDefaults.integer(forKey: key)
    }
}

private typealias Keys = SettingsKeys
