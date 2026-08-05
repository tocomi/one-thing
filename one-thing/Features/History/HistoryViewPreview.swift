#if DEBUG
import SwiftUI

/// Preview 用の HistoryView 組み立て。表示したい状態はリポジトリのシードで切り替える。
@MainActor
enum HistoryPreview {
    /// 固定した現在時刻と Calendar で HistoryViewModel を作る。
    static func makeViewModel(repository: ThingRepository) -> HistoryViewModel {
        HistoryViewModel(
            loadHistoryUseCase: LoadHistoryUseCase(
                repository: repository,
                calendar: PreviewClock.calendar
            ),
            loadEarliestHistoryDateUseCase: LoadEarliestHistoryDateUseCase(repository: repository),
            editHistoryUseCase: EditHistoryUseCase(repository: repository),
            deleteHistoryUseCase: DeleteHistoryUseCase(repository: repository),
            calendar: PreviewClock.calendar,
            userDefaults: PreviewUserDefaults.make(),
            dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase,
            nowProvider: { PreviewClock.now }
        )
    }

    /// Preview 用の HistoryView を作る。
    static func makeView(repository: ThingRepository) -> HistoryView {
        HistoryView(viewModel: makeViewModel(repository: repository))
    }
}

#Preview("履歴あり") {
    HistoryPreview.makeView(repository: PreviewThingSeed.makeDoneRepository())
}

#Preview("空") {
    HistoryPreview.makeView(repository: PreviewThingSeed.makeEmptyRepository())
}

#Preview("読み込みエラー") {
    HistoryPreview.makeView(repository: PreviewFailingThingRepository())
}
#endif
