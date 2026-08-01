import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("LoadOneThingUseCase")
struct LoadOneThingUseCaseTests {
    private let now = TestClock.date(2026, 8, 1, 10, 0)

    @Test("今日の Thing を取得する")
    func loadsTodayThing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 8, 1), title: "散歩する", status: .inProgress)
        ])

        let thing = try await makeUseCase(repository: repository).execute(now: now)

        #expect(thing?.title == "散歩する")
        #expect(repository.fetchThingDates == [TestClock.day(2026, 8, 1)])
    }

    @Test("今日の Thing がなければ nil を返す")
    func returnsNilWhenMissing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .done)
        ])

        let thing = try await makeUseCase(repository: repository).execute(now: now)

        #expect(thing == nil)
    }

    @Test("境界時刻より前は前日の Thing を返す")
    func usesDayBoundaryForTargetDate() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .inProgress)
        ])

        let thing = try await makeUseCase(repository: repository).execute(
            now: TestClock.date(2026, 8, 1, 3, 0),
            dayBoundaryMinutes: 240
        )

        #expect(thing?.title == "散歩する")
    }

    private func makeUseCase(repository: FakeThingRepository) -> LoadOneThingUseCase {
        LoadOneThingUseCase(
            repository: repository,
            dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar)
        )
    }
}
