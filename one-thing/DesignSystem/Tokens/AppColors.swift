import SwiftUI

/// アプリ全体のカラートークン。ライト・ダークモード双方に対応する。
extension Color {
    /// ページ背景：暖かみのあるクリーム（ライト）/ 深いウォームブラック（ダーク）。
    /// Launch Screen が同じ色を参照するため、定義元は Asset Catalog の LaunchBackground に置いている。
    static let appBackground = Color(.launchBackground)

    /// 入力フィールドや浮き上がる要素の面。
    static let appSurface = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.110, green: 0.104, blue: 0.094, alpha: 1)
            : UIColor(red: 0.950, green: 0.940, blue: 0.922, alpha: 1)
    })

    /// 見出し・本文など主要テキスト。
    static let appPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.922, blue: 0.894, alpha: 1)
            : UIColor(red: 0.102, green: 0.098, blue: 0.086, alpha: 1)
    })

    /// 補助情報や日付などのセカンダリテキスト。
    static let appSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.500, green: 0.468, blue: 0.424, alpha: 1)
            : UIColor(red: 0.490, green: 0.459, blue: 0.408, alpha: 1)
    })

    /// 主要アクション・強調に使うウォームアンバー。
    static let appAccent = Color(UIColor(red: 0.769, green: 0.533, blue: 0.133, alpha: 1))

    /// アンバーを薄く引いた背景用バリアント。
    static let appAccentSubtle = Color(UIColor(red: 0.769, green: 0.533, blue: 0.133, alpha: 0.12))

    /// 入力フィールドの枠線。
    static let appBorder = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.769, green: 0.533, blue: 0.133, alpha: 0.22)
            : UIColor(red: 0.769, green: 0.533, blue: 0.133, alpha: 0.25)
    })

    /// セパレーターや装飾ラインに使う控えめな色。
    static let appDivider = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.280, green: 0.263, blue: 0.239, alpha: 1)
            : UIColor(red: 0.820, green: 0.800, blue: 0.769, alpha: 1)
    })
}
