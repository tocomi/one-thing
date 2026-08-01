import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("CompleteOneThingUseCase")
struct CompleteOneThingUseCaseTests {
    private let now = TestClock.date(2026, 8, 1, 10, 0)

    @Test("今日の Thing を完了状態にして保存する")
    func completesTodayThing() async throws {
        let today = TestClock.day(2026, 8, 1)
        let repository = FakeThingRepository(things: [
            Thing(date: today, title: "散歩する", status: .inProgress)
        ])

        let thing = try await makeUseCase(repository: repository).execute(now: now)

        #expect(thing.status == .done)
        #expect(thing.isDone)
        #expect(repository.storedThing(on: today)?.status == .done)
        #expect(repository.saveChangesCallCount == 1)
    }

    @Test("今日の Thing がなければ thingNotFound を投げる")
    func throwsWhenThingIsMissing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .inProgress)
        ])

        await #expect(throws: CompleteOneThingUseCaseError.thingNotFound) {
            try await makeUseCase(repository: repository).execute(now: now)
        }
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("境界時刻より前は前日の Thing を完了にする")
    func usesDayBoundaryForTargetDate() async throws {
        let yesterday = TestClock.day(2026, 7, 31)
        let repository = FakeThingRepository(things: [
            Thing(date: yesterday, title: "散歩する", status: .inProgress)
        ])

        let thing = try await makeUseCase(repository: repository).execute(
            now: TestClock.date(2026, 8, 1, 3, 0),
            dayBoundaryMinutes: 240
        )

        #expect(thing.date == yesterday)
        #expect(thing.status == .done)
    }

    private func makeUseCase(repository: FakeThingRepository) -> CompleteOneThingUseCase {
        CompleteOneThingUseCase(
            repository: repository,
            dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar)
        )
    }
}
