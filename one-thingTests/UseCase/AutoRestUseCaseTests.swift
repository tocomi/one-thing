import Foundation
import Testing
@testable import one_thing

@MainActor
@Suite("AutoRestUseCase")
struct AutoRestUseCaseTests {
    private let now = TestClock.date(2026, 8, 1, 10, 0)

    @Test("前日の未完了タスクを rested に更新して保存する")
    func marksPreviousDayInProgressThingAsRested() async throws {
        let yesterday = TestClock.day(2026, 7, 31)
        let repository = FakeThingRepository(things: [
            Thing(date: yesterday, title: "散歩する", status: .inProgress)
        ])

        let updated = try await makeUseCase(repository: repository).execute(now: now)

        #expect(updated?.status == .rested)
        #expect(repository.storedThing(on: yesterday)?.status == .rested)
        #expect(repository.saveChangesCallCount == 1)
    }

    @Test("前日のタスクが完了済みなら何も変更しない")
    func keepsPreviousDayDoneThing() async throws {
        let yesterday = TestClock.day(2026, 7, 31)
        let repository = FakeThingRepository(things: [
            Thing(date: yesterday, title: "散歩する", status: .done)
        ])

        let updated = try await makeUseCase(repository: repository).execute(now: now)

        #expect(updated == nil)
        #expect(repository.storedThing(on: yesterday)?.status == .done)
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("前日のタスクがなければ何もしない")
    func doesNothingWithoutPreviousDayThing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 8, 1), title: "散歩する", status: .inProgress)
        ])

        let updated = try await makeUseCase(repository: repository).execute(now: now)

        #expect(updated == nil)
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("今日のタスクは対象にしない")
    func doesNotTouchTodayThing() async throws {
        let today = TestClock.day(2026, 8, 1)
        let repository = FakeThingRepository(things: [
            Thing(date: today, title: "散歩する", status: .inProgress)
        ])

        _ = try await makeUseCase(repository: repository).execute(now: now)

        #expect(repository.storedThing(on: today)?.status == .inProgress)
    }

    @Test("境界時刻より前は前々日を対象にする")
    func usesDayBoundaryToResolvePreviousDay() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 30), title: "散歩する", status: .inProgress),
            Thing(date: TestClock.day(2026, 7, 31), title: "本を読む", status: .inProgress)
        ])

        let updated = try await makeUseCase(repository: repository).execute(
            now: TestClock.date(2026, 8, 1, 3, 0),
            dayBoundaryMinutes: 240
        )

        #expect(updated?.title == "散歩する")
        #expect(repository.storedThing(on: TestClock.day(2026, 7, 31))?.status == .inProgress)
    }

    @Test("保存に失敗した場合はエラーを伝播する")
    func propagatesSaveError() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .inProgress)
        ])
        repository.errors[.saveChanges] = FakeRepositoryError()

        await #expect(throws: FakeRepositoryError.self) {
            try await makeUseCase(repository: repository).execute(now: now)
        }
    }

    private func makeUseCase(repository: FakeThingRepository) -> AutoRestUseCase {
        AutoRestUseCase(
            repository: repository,
            dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar),
            calendar: TestClock.calendar
        )
    }
}
