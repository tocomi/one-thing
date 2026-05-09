import Foundation

/// ホーム画面から表示する排他的な Sheet を表す。
enum HomeSheet: Hashable, Identifiable {
    case history
    case settings
    #if DEBUG
    case debugMenu
    #endif

    var id: Self { self }
}
