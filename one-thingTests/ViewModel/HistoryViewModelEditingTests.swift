import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("HistoryViewModel 編集できる日")
struct HistoryViewModelEditingTests {
    @Test("今日と未来日は編集できない日として扱う")
    func todayAndFutureAreNotEditable() async throws {
        let viewModel = makeHistoryViewModel(repository: FakeThingRepository())
        await viewModel.loadDisplayedMonthIfNeeded()

        let days = viewModel.days(for: TestClock.day(2026, 8, 1)) ?? []
        let today = try #require(days.first { $0.date == TestClock.fixedToday })
        let future = try #require(days.first { $0.date == TestClock.day(2026, 8, 2) })
        let empty = try #require(days.first { $0.date == nil })

        #expect(viewModel.isEditable(today) == false)
        #expect(viewModel.isEditable(future) == false)
        #expect(viewModel.isEditable(empty) == false)
    }

    @Test("過去日は編集できる日として扱う")
    func pastDaysAreEditable() async throws {
        let viewModel = makeHistoryViewModel(repository: FakeThingRepository())
        await viewModel.loadDisplayedMonthIfNeeded()
        viewModel.moveToPreviousMonth()
        await viewModel.loadDisplayedMonthIfNeeded()

        let days = viewModel.days(for: TestClock.day(2026, 7, 1)) ?? []
        let pastDay = try #require(days.first { $0.date == TestClock.day(2026, 7, 31) })

        #expect(viewModel.isEditable(pastDay))
    }

    @Test("今日の記録は履歴から保存できない")
    func doesNotSaveToday() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.fixedToday, title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        let saved = await viewModel.saveHistoryDay(
            date: TestClock.fixedToday,
            title: "本を読む",
            status: .rested
        )

        #expect(saved == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSaving == false)
        // 保存処理そのものを通していないため、今日の記録は元のまま残る。
        #expect(repository.saveChangesCallCount == 0)
        #expect(repository.createdThings.isEmpty)
        #expect(repository.storedThing(on: TestClock.fixedToday)?.status == .inProgress)
    }

    @Test("今日の記録は履歴から削除できない")
    func doesNotDeleteToday() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.fixedToday, title: "散歩する", status: .inProgress)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        let deleted = await viewModel.deleteHistoryDay(date: TestClock.fixedToday)

        #expect(deleted == false)
        #expect(viewModel.errorMessage != nil)
        #expect(repository.deletedDates.isEmpty)
        #expect(repository.storedThing(on: TestClock.fixedToday) != nil)
    }

    @Test("未来日も履歴から保存できない")
    func doesNotSaveFutureDay() async {
        let repository = FakeThingRepository()
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()

        let saved = await viewModel.saveHistoryDay(
            date: TestClock.day(2026, 8, 2),
            title: "散歩する",
            status: .done
        )

        #expect(saved == false)
        #expect(repository.createdThings.isEmpty)
    }

    @Test("過去日は保存も削除もできる")
    func editsPastDay() async {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .done)
        ])
        let viewModel = makeHistoryViewModel(repository: repository)
        await viewModel.loadDisplayedMonthIfNeeded()
        viewModel.moveToPreviousMonth()
        await viewModel.loadDisplayedMonthIfNeeded()

        let saved = await viewModel.saveHistoryDay(
            date: TestClock.day(2026, 7, 31),
            title: "本を読む",
            status: .rested
        )

        #expect(saved)
        #expect(viewModel.errorMessage == nil)
        #expect(repository.storedThing(on: TestClock.day(2026, 7, 31))?.title == "本を読む")
        #expect(repository.storedThing(on: TestClock.day(2026, 7, 31))?.status == .rested)

        let deleted = await viewModel.deleteHistoryDay(date: TestClock.day(2026, 7, 31))

        #expect(deleted)
        #expect(repository.storedThing(on: TestClock.day(2026, 7, 31)) == nil)
    }
}
