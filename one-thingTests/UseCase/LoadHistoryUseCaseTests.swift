import Foundation
import Testing
@testable import one_thing

@MainActor
@Suite("LoadHistoryUseCase")
struct LoadHistoryUseCaseTests {
    @Test("指定日を含む月の範囲でリポジトリを検索する")
    func fetchesMonthInterval() async throws {
        let repository = FakeThingRepository()

        _ = try await makeUseCase(repository: repository)
            .execute(monthContaining: TestClock.date(2026, 7, 15, 12, 0))

        #expect(repository.fetchRanges == [
            FakeThingRepository.FetchRange(
                startDate: TestClock.day(2026, 7, 1),
                endDate: TestClock.day(2026, 8, 1)
            )
        ])
    }

    @Test("該当月の Thing だけを日付昇順で返す")
    func returnsThingsInMonthSortedByDate() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "月末", status: .done),
            Thing(date: TestClock.day(2026, 6, 30), title: "前月", status: .done),
            Thing(date: TestClock.day(2026, 7, 1), title: "月初", status: .done),
            Thing(date: TestClock.day(2026, 8, 1), title: "翌月", status: .done)
        ])

        let things = try await makeUseCase(repository: repository)
            .execute(monthContaining: TestClock.day(2026, 7, 15))

        #expect(things.map(\.title) == ["月初", "月末"])
    }

    private func makeUseCase(repository: FakeThingRepository) -> LoadHistoryUseCase {
        LoadHistoryUseCase(repository: repository, calendar: TestClock.calendar)
    }
}
