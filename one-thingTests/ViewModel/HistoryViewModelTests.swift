import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HistoryViewModel 月ページ")
struct HistoryViewModelTests {
    @Test("記録がなくても既定の下限まで遡れる")
    func startsAtCurrentMonth() async {
        let viewModel = makeHistoryViewModel(repository: FakeThingRepository())

        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.monthText == "2026年8月")
        #expect(viewModel.isDisplayingCurrentMonth)
        #expect(viewModel.canMoveToNextMonth == false)
        // 過去の日は記録がなくても書けるため、記録の有無に関わらず遡れる。
        #expect(viewModel.canMoveToPreviousMonth)
        #expect(viewModel.months.first == TestClock.day(2016, 8, 1))
        #expect(viewModel.months.last == TestClock.day(2026, 8, 1))
        #expect(viewModel.months.sorted() == viewModel.months)
    }

    @Test("10 年より古い記録の月にも遡れる")
    func reachesRecordsOlderThanTenYears() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2009, 5, 4), title: "散歩する", status: .done)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)

        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.months.first == TestClock.day(2009, 5, 1))
        #expect(viewModel.months.contains(TestClock.day(2014, 6, 1)))
        // 2009 年 5 月から 2026 年 8 月までの月数。
        #expect(viewModel.months.count == 208)
    }

    @Test("月ページの先頭より過去へは移動しない")
    func doesNotMoveBeforeFirstMonthPage() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2009, 5, 4), title: "散歩する", status: .done)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()
        viewModel.displayedMonth = TestClock.day(2009, 5, 1)

        #expect(viewModel.canMoveToPreviousMonth == false)

        viewModel.moveToPreviousMonth()

        #expect(viewModel.displayedMonth == TestClock.day(2009, 5, 1))
    }

    @Test("今月表示中は翌月へ移動しない")
    func moveToNextMonthIgnoredOnCurrentMonth() {
        let viewModel = makeHistoryViewModel(repository: FakeThingRepository())

        viewModel.moveToNextMonth()

        #expect(viewModel.monthText == "2026年8月")
    }

    @Test("前月へ移動したあとは翌月へ戻れる")
    func moveToNextMonthReturnsToCurrentMonth() async {
        let viewModel = makeHistoryViewModel(repository: FakeThingRepository())
        await viewModel.loadDisplayedMonthIfNeeded()

        viewModel.moveToPreviousMonth()
        #expect(viewModel.canMoveToNextMonth)

        viewModel.moveToNextMonth()

        #expect(viewModel.monthText == "2026年8月")
        #expect(viewModel.canMoveToNextMonth == false)
    }

    @Test("開いたまま月が替わっても、ページ範囲と移動可否はずれない")
    func keepsMonthPagesConsistentAcrossMonthChange() async {
        let clock = MutableClock(now: TestClock.fixedNow)
        let viewModel = makeHistoryViewModel(
            repository: FakeThingRepository(),
            nowProvider: { clock.now }
        )
        await viewModel.loadDisplayedMonthIfNeeded()

        // シートを開いたまま月が替わった状況を再現する。
        clock.now = TestClock.date(2026, 9, 1, 10, 0)

        #expect(viewModel.months.last == TestClock.day(2026, 8, 1))
        #expect(viewModel.canMoveToNextMonth == false)
        viewModel.moveToNextMonth()
        #expect(viewModel.displayedMonth == TestClock.day(2026, 8, 1))

        // 開き直したときに、基準の月とページ範囲がまとめて新しくなる。
        viewModel.prepareForPresentation()
        await viewModel.loadDisplayedMonthIfNeeded()

        #expect(viewModel.displayedMonth == TestClock.day(2026, 9, 1))
        #expect(viewModel.months.last == TestClock.day(2026, 9, 1))
        #expect(viewModel.months.contains(TestClock.day(2026, 8, 1)))
        #expect(viewModel.canMoveToNextMonth == false)
        #expect(viewModel.canMoveToPreviousMonth)
    }

    @Test("シート表示前の準備で今月に戻り取得済みデータを捨てる")
    func prepareForPresentationResetsToCurrentMonth() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 10), title: "本を読む", status: .rested)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()
        viewModel.moveToPreviousMonth()
        await viewModel.loadDisplayedMonthIfNeeded()

        viewModel.prepareForPresentation()

        #expect(viewModel.monthText == "2026年8月")
        #expect(viewModel.days(for: TestClock.day(2026, 8, 1)) == nil)
        #expect(viewModel.days(for: TestClock.day(2026, 7, 1)) == nil)
        #expect(viewModel.selectedDay == nil)
        #expect(viewModel.months.first == TestClock.day(2016, 8, 1))
        #expect(viewModel.months.last == TestClock.day(2026, 8, 1))
    }
}
