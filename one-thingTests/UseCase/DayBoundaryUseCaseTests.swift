import Foundation
import Testing
@testable import one_thing

@MainActor
@Suite("DayBoundaryUseCase")
struct DayBoundaryUseCaseTests {
    private let useCase = DayBoundaryUseCase(calendar: TestClock.calendar)

    @Test("境界時刻を過ぎていればその日を今日として返す")
    func returnsCurrentDayAfterBoundary() {
        let today = useCase.execute(now: TestClock.date(2026, 8, 1, 4, 0), dayBoundaryHour: 4)

        #expect(today == TestClock.day(2026, 8, 1))
    }

    @Test("境界時刻より前なら前日を今日として返す")
    func returnsPreviousDayBeforeBoundary() {
        let today = useCase.execute(now: TestClock.date(2026, 8, 1, 3, 59), dayBoundaryHour: 4)

        #expect(today == TestClock.day(2026, 7, 31))
    }

    @Test("月をまたぐ場合も前日を正しく返す")
    func returnsPreviousMonthDayBeforeBoundary() {
        let today = useCase.execute(now: TestClock.date(2026, 8, 1, 0, 30), dayBoundaryHour: 4)

        #expect(today == TestClock.day(2026, 7, 31))
    }

    @Test("分単位の境界指定でも判定できる")
    func respectsBoundaryMinutes() {
        let beforeBoundary = useCase.execute(
            now: TestClock.date(2026, 8, 1, 2, 29),
            dayBoundaryMinutes: 150
        )
        let afterBoundary = useCase.execute(
            now: TestClock.date(2026, 8, 1, 2, 30),
            dayBoundaryMinutes: 150
        )

        #expect(beforeBoundary == TestClock.day(2026, 7, 31))
        #expect(afterBoundary == TestClock.day(2026, 8, 1))
    }

    @Test("負の境界値は 0 時として扱う")
    func clampsNegativeBoundaryMinutes() {
        let today = useCase.execute(
            now: TestClock.date(2026, 8, 1, 0, 0),
            dayBoundaryMinutes: -60
        )

        #expect(today == TestClock.day(2026, 8, 1))
    }

    @Test("24 時間以上の境界値は 23:59 として扱う")
    func clampsTooLargeBoundaryMinutes() {
        let beforeBoundary = useCase.execute(
            now: TestClock.date(2026, 8, 1, 23, 58),
            dayBoundaryMinutes: 24 * 60
        )
        let afterBoundary = useCase.execute(
            now: TestClock.date(2026, 8, 1, 23, 59),
            dayBoundaryMinutes: 24 * 60
        )

        #expect(beforeBoundary == TestClock.day(2026, 7, 31))
        #expect(afterBoundary == TestClock.day(2026, 8, 1))
    }

    @Test("既定の境界時刻は 4 時である")
    func defaultBoundaryIsFourOClock() {
        #expect(DayBoundaryUseCase.defaultBoundaryHour == 4)
        #expect(DayBoundaryUseCase.defaultBoundaryMinutes == 240)
    }
}
