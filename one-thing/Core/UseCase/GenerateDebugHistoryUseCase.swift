import Foundation

/// 開発確認用に過去日のランダムな履歴データを生成するユースケース。
struct GenerateDebugHistoryUseCase {
    private let repository: ThingRepository
    private let calendar: Calendar
    private let titles = [
        "散歩する",
        "本を読む",
        "日記を書く",
        "水を飲む",
        "机を片付ける",
        "ストレッチする"
    ]

    /// タスク保存先と日付計算に使う Calendar を受け取る。
    init(repository: ThingRepository, calendar: Calendar = .autoupdatingCurrent) {
        self.repository = repository
        self.calendar = calendar
    }

    /// 既存データを削除し、昨日までの過去 30 日にランダムな履歴を作成する。
    func execute(now: Date = Date(), days: Int = 30) async throws {
        try await repository.deleteAllThings()

        let today = calendar.startOfDay(for: now)

        for offset in 1...days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                continue
            }

            guard Bool.random() else {
                continue
            }

            _ = try await repository.createThing(
                date: date,
                title: titles.randomElement() ?? "ひとつやる",
                status: Bool.random() ? .done : .rested
            )
        }
    }
}
