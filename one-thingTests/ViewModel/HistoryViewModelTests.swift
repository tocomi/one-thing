import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HistoryViewModel")
struct HistoryViewModelTests {
    @Test("初期表示は今月で、翌月へは移動できない")
    func startsAtCurrentMonth() {
        let viewModel = makeViewModel(repository: FakeThingRepository())

        #expect(viewModel.monthText == "2026年8月")
        #expect(viewModel.isDisplayingCurrentMonth)
        #expect(viewModel.canMoveToNextMonth == false)
        #expect(viewModel.canMoveToPreviousMonth)
    }

    @Test("前月へ移動するとその月の履歴を読み込む")
    func moveToPreviousMonthLoadsThatMonth() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 10), title: "散歩する", status: .done)
        ])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.moveToPreviousMonth()

        #expect(viewModel.monthText == "2026年7月")
        #expect(repository.fetchRanges == [
            FakeThingRepository.FetchRange(
                startDate: TestClock.day(2026, 7, 1),
                endDate: TestClock.day(2026, 8, 1)
            )
        ])
        #expect(viewModel.days.filter { $0.date != nil }.count == 31)
        #expect(viewModel.days.first { $0.thing != nil }?.thing?.title == "散歩する")
        #expect(viewModel.isLoading == false)
    }

    @Test("前月へ移動すると翌月へ戻れるようになる")
    func moveToNextMonthReturnsToCurrentMonth() async {
        let viewModel = makeViewModel(repository: FakeThingRepository())

        await viewModel.moveToPreviousMonth()
        #expect(viewModel.canMoveToNextMonth)

        await viewModel.moveToNextMonth()

        #expect(viewModel.monthText == "2026年8月")
        #expect(viewModel.canMoveToNextMonth == false)
    }

    @Test("今月表示中に翌月へ移動しても月は変わらない")
    func moveToNextMonthIgnoredOnCurrentMonth() async {
        let repository = FakeThingRepository()
        let viewModel = makeViewModel(repository: repository)

        await viewModel.moveToNextMonth()

        #expect(viewModel.monthText == "2026年8月")
        #expect(repository.fetchRanges.isEmpty)
    }

    @Test("読み込みの完了前に月移動を重ねてもリクエストは重複しない")
    func monthMoveIsIgnoredWhileLoading() async {
        let repository = FakeThingRepository()
        repository.suspendsFetchThings = true
        let viewModel = makeViewModel(repository: repository)

        async let firstMove: Void = viewModel.moveToPreviousMonth()
        #expect(await waitUntil { repository.fetchRanges.count == 1 })
        #expect(viewModel.isLoading)

        // 読み込みが終わる前に前月・翌月を連打した状況を再現する。
        // ガードが外れると追加の読み込みが待機に入るため、待ち合わせずに実行して回数だけを見る。
        async let secondMove: Void = viewModel.moveToPreviousMonth()
        async let thirdMove: Void = viewModel.moveToNextMonth()
        _ = await waitUntil { repository.fetchRanges.count > 1 }

        #expect(repository.fetchRanges.count == 1)
        #expect(viewModel.monthText == "2026年7月")

        repository.resumeFetchThings()
        _ = await(firstMove, secondMove, thirdMove)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.monthText == "2026年7月")
        #expect(repository.fetchRanges.count == 1)
    }

    @Test("読み込みに失敗するとエラーメッセージを表示して読み込みを終える")
    func loadSurfacesError() async {
        let repository = FakeThingRepository()
        repository.errors[.fetchThings] = FakeRepositoryError()
        let viewModel = makeViewModel(repository: repository)

        await viewModel.moveToPreviousMonth()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.days.isEmpty)
        #expect(viewModel.isLoading == false)
        // エラー表示のあとでも月移動は続けられる。
        #expect(viewModel.canMoveToPreviousMonth)
    }

    @Test("再読み込みに成功すると前回のエラー表示は消える")
    func loadClearsPreviousError() async {
        let repository = FakeThingRepository()
        repository.errors[.fetchThings] = FakeRepositoryError()
        let viewModel = makeViewModel(repository: repository)
        await viewModel.moveToPreviousMonth()

        repository.errors.removeValue(forKey: .fetchThings)
        await viewModel.moveToPreviousMonth()

        #expect(viewModel.monthText == "2026年6月")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.days.isEmpty == false)
    }

    /// 並行して走らせた処理が指定の状態になるまで待つ。無限待ちを避けるため回数で打ち切る。
    func waitUntil(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<1000 {
            if condition() {
                return true
            }

            await Task.yield()
        }

        return condition()
    }

    /// fake リポジトリと固定時刻を差し替えた HistoryViewModel を組み立てる。
    func makeViewModel(
        repository: FakeThingRepository,
        now: Date = TestClock.fixedNow
    ) -> HistoryViewModel {
        HistoryViewModel(
            loadHistoryUseCase: LoadHistoryUseCase(
                repository: repository,
                calendar: TestClock.calendar
            ),
            editHistoryUseCase: EditHistoryUseCase(repository: repository),
            deleteHistoryUseCase: DeleteHistoryUseCase(repository: repository),
            calendar: TestClock.calendar,
            userDefaults: makeIsolatedUserDefaults(),
            dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar),
            nowProvider: { now }
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
}
