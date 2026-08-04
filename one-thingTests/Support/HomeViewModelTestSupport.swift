import Foundation
@testable import one_thing

/// fake リポジトリと固定時刻を差し替えた HomeViewModel を組み立てる。
@MainActor
func makeHomeViewModel(
    repository: FakeThingRepository,
    now: Date = TestClock.fixedNow
) -> HomeViewModel {
    let dayBoundaryUseCase = DayBoundaryUseCase(calendar: TestClock.calendar)

    return HomeViewModel(
        loadOneThingUseCase: LoadOneThingUseCase(
            repository: repository,
            dayBoundaryUseCase: dayBoundaryUseCase
        ),
        setOneThingUseCase: SetOneThingUseCase(
            repository: repository,
            dayBoundaryUseCase: dayBoundaryUseCase
        ),
        completeOneThingUseCase: CompleteOneThingUseCase(
            repository: repository,
            dayBoundaryUseCase: dayBoundaryUseCase
        ),
        autoRestUseCase: AutoRestUseCase(
            repository: repository,
            dayBoundaryUseCase: dayBoundaryUseCase,
            calendar: TestClock.calendar
        ),
        resetThingDataUseCase: ResetThingDataUseCase(repository: repository),
        suggestThingsUseCase: SuggestThingsUseCase(
            repository: repository,
            dayBoundaryUseCase: dayBoundaryUseCase,
            calendar: TestClock.calendar
        ),
        generateDebugHistoryUseCase: GenerateDebugHistoryUseCase(
            repository: repository,
            calendar: TestClock.calendar
        ),
        calendar: TestClock.calendar,
        userDefaults: makeIsolatedUserDefaults(),
        dayBoundaryUseCase: dayBoundaryUseCase,
        nowProvider: { now }
    )
}

/// HomeViewModel に固定時刻を注入しているため、テスト側の「今日」も固定値で表せる。
func appToday() -> Date {
    TestClock.fixedToday
}

/// 今日から指定日数さかのぼった日付を返す。
func pastDay(_ offset: Int) -> Date {
    TestClock.calendar.date(byAdding: .day, value: -offset, to: appToday()) ?? appToday()
}
