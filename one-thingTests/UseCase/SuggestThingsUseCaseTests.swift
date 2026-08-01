import Foundation
@testable import one_thing
import Testing

@MainActor
@Suite("SuggestThingsUseCase")
struct SuggestThingsUseCaseTests {
    private let now = TestClock.date(2026, 8, 1, 10, 0)

    @Test("出現回数の多いタイトルから順に返す")
    func sortsByFrequency() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 29), title: "散歩する", status: .done),
            Thing(date: TestClock.day(2026, 7, 30), title: "散歩する", status: .done),
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .done),
            Thing(date: TestClock.day(2026, 7, 27), title: "本を読む", status: .done),
            Thing(date: TestClock.day(2026, 7, 28), title: "本を読む", status: .rested),
            Thing(date: TestClock.day(2026, 7, 26), title: "日記を書く", status: .done)
        ])

        let suggestions = try await makeUseCase(repository: repository).execute(now: now)

        #expect(suggestions == ["散歩する", "本を読む", "日記を書く"])
    }

    @Test("回数が同じ場合は直近に使ったタイトルを優先する")
    func breaksTieByLastUsedDate() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 20), title: "古い習慣", status: .done),
            Thing(date: TestClock.day(2026, 7, 31), title: "新しい習慣", status: .done)
        ])

        let suggestions = try await makeUseCase(repository: repository).execute(now: now)

        #expect(suggestions == ["新しい習慣", "古い習慣"])
    }

    @Test("回数も最終利用日も同じ場合はタイトル順で並べる")
    func breaksTieByTitle() async throws {
        let sameDay = TestClock.day(2026, 7, 31)
        let repository = FakeThingRepository(things: [
            Thing(date: sameDay, title: "読書", status: .done),
            Thing(date: sameDay, title: "散歩", status: .done)
        ])

        let suggestions = try await makeUseCase(repository: repository).execute(now: now)

        #expect(suggestions == ["散歩", "読書"])
    }

    @Test("前後の空白を無視して同じタイトルとして集計する")
    func trimsWhitespaceBeforeCounting() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 29), title: " 散歩する ", status: .done),
            Thing(date: TestClock.day(2026, 7, 30), title: "散歩する", status: .done),
            Thing(date: TestClock.day(2026, 7, 31), title: "   ", status: .rested)
        ])

        let suggestions = try await makeUseCase(repository: repository).execute(now: now)

        #expect(suggestions == ["散歩する"])
    }

    @Test("limit の件数までに絞り込む")
    func limitsResultCount() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 28), title: "散歩する", status: .done),
            Thing(date: TestClock.day(2026, 7, 29), title: "散歩する", status: .done),
            Thing(date: TestClock.day(2026, 7, 30), title: "本を読む", status: .done),
            Thing(date: TestClock.day(2026, 7, 31), title: "日記を書く", status: .done)
        ])

        let suggestions = try await makeUseCase(repository: repository).execute(now: now, limit: 2)

        #expect(suggestions == ["散歩する", "日記を書く"])
    }

    @Test("limit が 0 以下ならリポジトリを呼ばずに空配列を返す")
    func returnsEmptyForNonPositiveLimit() async throws {
        let repository = FakeThingRepository(things: [
            Thing(date: TestClock.day(2026, 7, 31), title: "散歩する", status: .done)
        ])

        let suggestions = try await makeUseCase(repository: repository).execute(now: now, limit: 0)

        #expect(suggestions.isEmpty)
        #expect(repository.fetchRanges.isEmpty)
    }

    @Test("今日を含まない直近 1 年分を取得対象にする")
    func fetchesLastOneYearBeforeToday() async throws {
        let repository = FakeThingRepository()

        _ = try await makeUseCase(repository: repository).execute(now: now)

        #expect(repository.fetchRanges == [
            FakeThingRepository.FetchRange(
                startDate: TestClock.day(2025, 8, 1),
                endDate: TestClock.day(2026, 8, 1)
            )
        ])
    }

    @Test("境界時刻より前は前日を今日として取得範囲を決める")
    func usesDayBoundaryForFetchRange() async throws {
        let repository = FakeThingRepository()

        _ = try await makeUseCase(repository: repository).execute(
            now: TestClock.date(2026, 8, 1, 3, 0),
            dayBoundaryMinutes: 240
        )

        #expect(repository.fetchRanges.first?.endDate == TestClock.day(2026, 7, 31))
    }

    private func makeUseCase(repository: FakeThingRepository) -> SuggestThingsUseCase {
        SuggestThingsUseCase(
            repository: repository,
            dayBoundaryUseCase: DayBoundaryUseCase(calendar: TestClock.calendar),
            calendar: TestClock.calendar
        )
    }
}
