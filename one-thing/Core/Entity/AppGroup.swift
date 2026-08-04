/// アプリ本体とウィジェットで共有する App Group の設定。
///
/// 共有 UserDefaults の生成は Data 層の実装が担う。ここでは entitlements に
/// 登録した ID だけを公開し、Core が永続化の詳細に依存しないようにする。
enum AppGroup {
    /// 各 Target の entitlements に登録した App Group ID。
    static let identifier = "group.net.tocomi.one-thing"
}
