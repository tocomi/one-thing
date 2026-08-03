import Foundation
@testable import one_thing

/// テスト中に現在時刻を進められるようにする箱。
@MainActor
final class MutableClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

/// fake リポジトリと固定時刻を差し替えた HistoryViewModel を組み立てる。
@MainActor
func makeHistoryViewModel(
    repository: FakeThingRepository,
    nowProvider: @escaping () -> Date = { TestClock.fixedNow }
) -> HistoryViewModel {
    HistoryViewModel(
        loadHistoryUseCase: LoadHistoryUseCase(
            repository: repository,
            calendar: TestClock.calendar
        ),
        loadEarliestHistoryDateUseCase: LoadEarliestHistoryDateUseCase(repository: repository),
        editHistoryUseCase: EditHistoryUseCase(repository: repository),
        deleteHistoryUseCase: DeleteHistoryUseCase(repository: repository),
        calendar: TestClock.calendar,
        userDefaults: makeIsolatedUserDefaults(),
        dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar),
        nowProvider: nowProvider
    )
}

/// テスト間で設定値が混ざらないよう、テストごとに空の UserDefaults を用意する。
func makeIsolatedUserDefaults() -> UserDefaults {
    let suiteName = "one-thingTests.\(UUID().uuidString)"

    guard let userDefaults = UserDefaults(suiteName: suiteName) else {
        preconditionFailure("テスト用の UserDefaults を作成できませんでした: \(suiteName)")
    }

    return userDefaults
}

/// 並行して走らせた処理が指定の状態になるまで待つ。無限待ちを避けるため回数で打ち切る。
/// 待つ間はメインアクターを譲るだけにして、監視する状態を必ずメインアクター上で読む。
@MainActor
func waitUntil(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<1000 {
        if condition() {
            return true
        }

        await Task.yield()
    }

    return condition()
}
