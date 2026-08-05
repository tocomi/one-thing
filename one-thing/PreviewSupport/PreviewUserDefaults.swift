#if DEBUG
import Foundation

/// Preview の表示を端末の実際の設定値から切り離すため、Preview 専用の UserDefaults を用意する。
enum PreviewUserDefaults {
    /// 渡した値だけを持つ UserDefaults を作る。Preview ごとに別の suite にして状態を持ち越さない。
    ///
    /// 隔離に失敗したまま `UserDefaults.standard` へ流れると実際の設定を読み書きしてしまうため、
    /// suite を作れない場合はフォールバックせずその場で止める。
    static func make(_ values: [String: Any] = [:]) -> UserDefaults {
        let suiteName = "preview.\(UUID().uuidString)"

        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Preview 専用の UserDefaults を作成できませんでした: \(suiteName)")
        }

        // register(defaults:) の登録ドメインはプロセス全体で共有され UserDefaults.standard からも
        // 見えてしまうため、隔離のために suite の永続ドメインへ書く。
        defaults.removePersistentDomain(forName: suiteName)

        for (key, value) in values {
            defaults.set(value, forKey: key)
        }

        return defaults
    }
}
#endif
