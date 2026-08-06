#if DEBUG
import SwiftUI

/// Preview 用の HomeView 組み立て。表示したい状態はリポジトリのシードで切り替える。
@MainActor
enum HomePreview {
    /// 固定した現在時刻と Calendar で HomeViewModel を作る。
    static func makeViewModel(repository: ThingRepository) -> HomeViewModel {
        HomeViewModel(
            loadOneThingUseCase: LoadOneThingUseCase(
                repository: repository,
                dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase
            ),
            setOneThingUseCase: SetOneThingUseCase(
                repository: repository,
                dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase
            ),
            completeOneThingUseCase: CompleteOneThingUseCase(
                repository: repository,
                dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase
            ),
            autoRestUseCase: AutoRestUseCase(
                repository: repository,
                dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase,
                calendar: PreviewClock.calendar
            ),
            resetThingDataUseCase: ResetThingDataUseCase(repository: repository),
            suggestThingsUseCase: SuggestThingsUseCase(
                repository: repository,
                dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase,
                calendar: PreviewClock.calendar
            ),
            generateDebugHistoryUseCase: GenerateDebugHistoryUseCase(
                repository: repository,
                calendar: PreviewClock.calendar
            ),
            calendar: PreviewClock.calendar,
            userDefaults: PreviewUserDefaults.make(),
            dayBoundaryUseCase: PreviewClock.dayBoundaryUseCase,
            nowProvider: { PreviewClock.now }
        )
    }

    /// Preview 用の HomeView を作る。履歴シートも同じリポジトリを見る。
    /// 設定シートも Preview 用の依存で組み立て、実際の設定値や通知許可には触れない。
    static func makeView(repository: ThingRepository) -> HomeView {
        HomeView(
            viewModel: makeViewModel(repository: repository),
            historyViewModel: HistoryPreview.makeViewModel(repository: repository),
            makeSettingsViewModel: { SettingsPreview.makeViewModel(receivesNotifications: true) }
        )
    }
}

#Preview("未設定") {
    HomePreview.makeView(repository: PreviewThingSeed.makeRecordedRepository())
}

#Preview("未設定（候補なし）") {
    HomePreview.makeView(repository: PreviewThingSeed.makeEmptyRepository())
}

#Preview("進行中") {
    HomePreview.makeView(repository: PreviewThingSeed.makeInProgressRepository())
}

#Preview("完了") {
    HomePreview.makeView(repository: PreviewThingSeed.makeDoneRepository())
}

// 今日が「休んだ」の記録でも完了扱いにはせず、未設定として決め直せる状態を確認する。
#Preview("今日が休んだ") {
    HomePreview.makeView(repository: PreviewThingSeed.makeRestedTodayRepository())
}

// 編集中は読み込みのたびに解除される一時状態のため、HomeView 経由では固定できない。
// 入力欄と操作ボタンの見え方は HomeInProgressView の Preview で確認する。

#Preview("読み込みエラー") {
    HomePreview.makeView(repository: PreviewFailingThingRepository())
}
#endif
