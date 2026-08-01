import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("SetOneThingUseCase")
struct SetOneThingUseCaseTests {
    private let now = TestClock.date(2026, 8, 1, 10, 0)

    @Test("今日の Thing がなければ新規作成する")
    func createsThingWhenMissing() async throws {
        let repository = FakeThingRepository()

        let thing = try await makeUseCase(repository: repository).execute(
            title: "散歩する",
            now: now
        )

        #expect(thing.title == "散歩する")
        #expect(thing.status == .inProgress)
        #expect(thing.date == TestClock.day(2026, 8, 1))
        #expect(repository.createdThings.count == 1)
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("今日の Thing があればタイトルと状態を更新する")
    func updatesExistingThing() async throws {
        let today = TestClock.day(2026, 8, 1)
        let repository = FakeThingRepository(things: [
            Thing(date: today, title: "本を読む", status: .rested)
        ])

        let thing = try await makeUseCase(repository: repository).execute(
            title: "散歩する",
            now: now
        )

        #expect(thing.title == "散歩する")
        #expect(thing.status == .inProgress)
        #expect(repository.createdThings.isEmpty)
        #expect(repository.saveChangesCallCount == 1)
    }

    @Test("境界時刻より前は前日の日付で保存する")
    func usesDayBoundaryForTargetDate() async throws {
        let repository = FakeThingRepository()

        let thing = try await makeUseCase(repository: repository).execute(
            title: "散歩する",
            now: TestClock.date(2026, 8, 1, 3, 0),
            dayBoundaryMinutes: 240
        )

        #expect(thing.date == TestClock.day(2026, 7, 31))
    }

    private func makeUseCase(repository: FakeThingRepository) -> SetOneThingUseCase {
        SetOneThingUseCase(
            repository: repository,
            dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar)
        )
    }
}
