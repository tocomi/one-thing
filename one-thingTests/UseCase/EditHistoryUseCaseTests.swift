import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("EditHistoryUseCase")
struct EditHistoryUseCaseTests {
    private let targetDate = TestClock.day(2026, 7, 20)

    @Test("既存の Thing のタイトルと状態を更新する")
    func updatesExistingThing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: targetDate, title: "本を読む", status: .inProgress)
        ])

        let result = try await EditHistoryUseCase(repository: repository).execute(
            date: targetDate,
            title: "散歩する",
            status: .done
        )

        #expect(result.thing.title == "散歩する")
        #expect(result.thing.status == .done)
        #expect(repository.saveChangesCallCount == 1)
    }

    @Test("タイトルの前後空白を取り除いて保存する")
    func trimsTitleWhitespace() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: targetDate, title: "本を読む", status: .done)
        ])

        let result = try await EditHistoryUseCase(repository: repository).execute(
            date: targetDate,
            title: "  散歩する  "
        )

        #expect(result.thing.title == "散歩する")
        #expect(result.thing.status == .done)
    }

    @Test("該当日の Thing がなければ新規作成する")
    func createsThingWhenMissing() async throws {
        let repository = FakeThingRepository()

        let result = try await EditHistoryUseCase(repository: repository).execute(
            date: targetDate,
            title: "散歩する"
        )

        #expect(result.thing.date == targetDate)
        #expect(result.thing.status == .done)
        #expect(repository.createdThings.count == 1)
    }

    @Test("新規作成時は指定した状態を使う")
    func createsThingWithGivenStatus() async throws {
        let repository = FakeThingRepository()

        let result = try await EditHistoryUseCase(repository: repository).execute(
            date: targetDate,
            title: "散歩する",
            status: .rested
        )

        #expect(result.thing.status == .rested)
    }

    @Test("変更内容がなければ noChanges を投げる")
    func throwsWhenNothingChanges() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: targetDate, title: "本を読む", status: .done)
        ])

        await #expect(throws: EditHistoryUseCaseError.noChanges) {
            try await EditHistoryUseCase(repository: repository).execute(date: targetDate)
        }
    }

    @Test("空白だけのタイトルは emptyTitle を投げる")
    func throwsForBlankTitleOnExistingThing() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: targetDate, title: "本を読む", status: .done)
        ])

        await #expect(throws: EditHistoryUseCaseError.emptyTitle) {
            try await EditHistoryUseCase(repository: repository).execute(
                date: targetDate,
                title: "   "
            )
        }
        #expect(repository.saveChangesCallCount == 0)
    }

    @Test("新規作成でタイトルがなければ emptyTitle を投げる")
    func throwsForMissingTitleOnCreate() async throws {
        let repository = FakeThingRepository()

        await #expect(throws: EditHistoryUseCaseError.emptyTitle) {
            try await EditHistoryUseCase(repository: repository).execute(
                date: targetDate,
                status: .done
            )
        }
        #expect(repository.createdThings.isEmpty)
    }
}
