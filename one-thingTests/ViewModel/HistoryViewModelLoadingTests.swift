import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HistoryViewModel 月の読み込み")
struct HistoryViewModelLoadingTests {
    @Test("表示中の月を読み込むとその月の履歴がページに入る")
    func loadsDisplayedMonth() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 8, 2), title: "散歩する", status: .done)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)

        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(repository.fetchRanges == [
            FakeThingRepository.FetchRange(
                startDate: TestClock.day(2026, 8, 1),
                endDate: TestClock.day(2026, 9, 1)
            )
        ])
        let days = viewModel.days(for: TestClock.day(2026, 8, 1))
        #expect(days?.filter { $0.date != nil }.count == 31)
        #expect(days?.first { $0.thing != nil }?.thing?.title == "散歩する")
        #expect(viewModel.isLoading(TestClock.day(2026, 8, 1)) == false)
    }

    @Test("取得済みの月は読み直さない")
    func doesNotReloadCachedMonth() async {
        let repository = FakeThingRepository()
        let viewModel = makeHistoryViewModel(repository: repository)

        await viewModel.loadDisplayedMonthIfNeeded()
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(repository.fetchRanges.count == 1)
        #expect(repository.fetchEarliestThingCallCount == 1)
    }

    @Test("前月へ移動するとその月を読み込み、今月の表示は残る")
    func moveToPreviousMonthKeepsLoadedMonths() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 10), title: "本を読む", status: .rested)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        viewModel.moveToPreviousMonth()
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.monthText == "2026年7月")
        #expect(viewModel.days(for: TestClock.day(2026, 7, 1))?.isEmpty == false)
        // 別の月へ移っても、読み込み済みの月のデータは保持する。
        #expect(viewModel.days(for: TestClock.day(2026, 8, 1))?.isEmpty == false)
        #expect(repository.fetchRanges.count == 2)
    }

    @Test("記録のない過去の月も開いて書き込める")
    func editsMonthWithoutRecords() async {
        let repository = FakeThingRepository()
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        for _ in 0..<3 {
            viewModel.moveToPreviousMonth()
        }
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.monthText == "2026年5月")
        #expect(viewModel.days(for: TestClock.day(2026, 5, 1))?.isEmpty == false)

        let saved = await viewModel.saveHistoryDay(
            date: TestClock.day(2026, 5, 20),
            title: "散歩する",
            status: .done
        )

        #expect(saved)
        #expect(repository.storedThing(on: TestClock.day(2026, 5, 20))?.title == "散歩する")
        #expect(viewModel.days(for: TestClock.day(2026, 5, 1))?
            .first { $0.thing != nil }?.thing?.title == "散歩する")
    }

    @Test("読み込みの完了前に同じ月の読み込みを重ねてもリクエストは重複しない")
    func doesNotDuplicateRequestForSameMonth() async {
        let repository = FakeThingRepository()
        repository.suspendsFetchThings = true
        let viewModel = makeHistoryViewModel(repository: repository)

        async let firstLoad: Void = viewModel.loadDisplayedMonthIfNeeded()
        #expect(await waitUntil { repository.fetchRanges.count == 1 })
        #expect(viewModel.isLoading(TestClock.day(2026, 8, 1)))

        // 読み込みが終わる前に同じ月の読み込みが重ねて要求された状況を再現する。
        async let secondLoad: Void = viewModel.loadDisplayedMonthIfNeeded()
        _ = await waitUntil { repository.fetchRanges.count > 1 }

        #expect(repository.fetchRanges.count == 1)

        repository.resumeFetchThings()
        _ = await(firstLoad, secondLoad)

        #expect(repository.fetchRanges.count == 1)
        #expect(viewModel.isLoading(TestClock.day(2026, 8, 1)) == false)
    }

    @Test("表示をリセットすると、リセット前に始まった読み込みの結果は書き戻らない")
    func discardsResultsStartedBeforeReset() async {
        let repository = FakeThingRepository()
        repository.suspendsFetchThings = true
        let viewModel = makeHistoryViewModel(repository: repository)

        async let staleLoad: Void = viewModel.loadDisplayedMonthIfNeeded()
        #expect(await waitUntil { repository.fetchRanges.count == 1 })

        // シートを閉じて開き直した状況を再現する。
        viewModel.prepareForPresentation()

        // 開き直したあとの読み込みは失敗させ、古い成功結果が書き戻れば見分けられるようにする。
        repository.suspendsFetchThings = false
        repository.errors[.fetchThings] = FakeRepositoryError()
        await viewModel.loadDisplayedMonthIfNeeded()

        // 前の読み込みが残っていても新しい読み込みを開始できたことは、その失敗が記録されたことでわかる。
        #expect(viewModel.loadError(for: TestClock.day(2026, 8, 1)) != nil)

        repository.resumeFetchThings()
        await staleLoad

        // 古い読み込みの成功結果でエラー表示が上書きされない。
        #expect(viewModel.days(for: TestClock.day(2026, 8, 1)) == nil)
        #expect(viewModel.loadError(for: TestClock.day(2026, 8, 1)) != nil)
        #expect(viewModel.isLoading(TestClock.day(2026, 8, 1)) == false)

        // 読み込み中の状態も残っていないため、そのまま読み込み直せる。
        repository.errors.removeValue(forKey: .fetchThings)
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.days(for: TestClock.day(2026, 8, 1))?.isEmpty == false)
        #expect(viewModel.loadError(for: TestClock.day(2026, 8, 1)) == nil)
    }

    @Test("読み込み中は表示中の月だけが読み込み状態になる")
    func loadingIsScopedToDisplayedMonth() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 10), title: "本を読む", status: .rested)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        repository.suspendsFetchThings = true
        viewModel.moveToPreviousMonth()
        async let move: Void = viewModel.loadDisplayedMonthIfNeeded()
        #expect(await waitUntil { viewModel.isLoading(TestClock.day(2026, 7, 1)) })

        // 読み込み中でも、読み込み済みの月の表示は保たれる。
        #expect(viewModel.isLoading(TestClock.day(2026, 8, 1)) == false)
        #expect(viewModel.days(for: TestClock.day(2026, 8, 1))?.isEmpty == false)
        #expect(viewModel.days(for: TestClock.day(2026, 7, 1)) == nil)

        repository.resumeFetchThings()
        await move
    }

    @Test("読み込みに失敗した月にだけエラーメッセージを持つ")
    func loadErrorIsScopedToMonth() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 10), title: "本を読む", status: .rested)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        repository.errors[.fetchThings] = FakeRepositoryError()
        viewModel.moveToPreviousMonth()
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.loadError(for: TestClock.day(2026, 7, 1)) != nil)
        #expect(viewModel.loadError(for: TestClock.day(2026, 8, 1)) == nil)
        #expect(viewModel.days(for: TestClock.day(2026, 7, 1)) == nil)
        #expect(viewModel.isLoading(TestClock.day(2026, 7, 1)) == false)
    }

    @Test("失敗した月へ戻ると読み込み直してエラー表示が消える")
    func retriesFailedMonth() async {
        let repository = FakeThingRepository()
        repository.errors[.fetchThings] = FakeRepositoryError()
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        repository.errors.removeValue(forKey: .fetchThings)
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.loadError(for: TestClock.day(2026, 8, 1)) == nil)
        #expect(viewModel.days(for: TestClock.day(2026, 8, 1))?.isEmpty == false)
    }

    @Test("履歴を保存すると表示中の月を読み直す")
    func saveReloadsDisplayedMonth() async {
        let repository = FakeThingRepository()
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()
        // 基準にしている今日は 8 月 1 日のため、編集できる過去日を持つ前月を表示する。
        viewModel.moveToPreviousMonth()
        await viewModel.loadDisplayedMonthIfNeeded()

        let saved = await viewModel.saveHistoryDay(
            date: TestClock.day(2026, 7, 2),
            title: "散歩する",
            status: .done
        )

        #expect(saved)
        #expect(repository.fetchRanges.count == 3)
        #expect(viewModel.days(for: TestClock.day(2026, 7, 1))?
            .first { $0.thing != nil }?.thing?.title == "散歩する")
        #expect(viewModel.selectedDay?.thing?.title == "散歩する")
    }
}
