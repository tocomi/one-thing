import Foundation

/// 履歴で「その日の結果」を言い表すコピー。
/// 日次詳細（過去日・今日）とカレンダーの読み上げで同じ言葉を使うため、ここに集約する。
enum HistoryResultText {
    /// 記録の状態に対応する結果のコピーを返す。記録がない日は「記録なし」。
    static func text(for status: ThingStatus?) -> String {
        switch status {
        case .done:
            "できた"
        case .rested:
            "休んだ"
        // 今日を選ぶとまだ結果の出ていない記録も表示されるため、進行中も結果として言い分ける。
        case .inProgress:
            "進行中"
        default:
            "記録なし"
        }
    }
}
