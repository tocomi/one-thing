import SwiftUI
import WidgetKit

/// Target 追加を確認するための最小エントリ。
///
/// 表示するデータは持たない。今日のタスク名・状態・区切り時刻を運ぶ
/// `WidgetEntry` は Core 側で定義し、この型と Provider ごと差し替える。
struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

/// 固定のプレースホルダーだけを返す暫定プロバイダー。
///
/// 共有データの読み込みとリロード方針は Timeline Provider の実装で入れ替える。
struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
    }
}

/// Target が動作することと AppColors を参照できることだけを示す暫定 View。
///
/// 状態別の見た目とタップ時の遷移は Widget View の実装で作り込む。
struct PlaceholderWidgetView: View {
    var body: some View {
        Text("ONE THING")
            .font(.headline)
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(Color.appBackground, for: .widget)
    }
}

/// ホーム画面に追加できるウィジェットの定義。サイズは Small のみを提供する。
struct OneThingWidget: Widget {
    private let kind = "OneThingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
            PlaceholderWidgetView()
        }
        .configurationDisplayName("ONE THING")
        .description("今日の ONE THING をホーム画面に表示します。")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    OneThingWidget()
} timeline: {
    PlaceholderEntry(date: Date())
}
