//
//  OneThingApp.swift
//  one-thing
//
//  Created by Kenta TSUNEMI on 2026/05/05.
//

import SwiftData
import SwiftUI

/// アプリの起動点として永続化コンテナを準備し、ルート画面へ依存関係を渡す。
@main
struct OneThingApp: App {
    private let modelContainer: ModelContainer

    /// SwiftData のモデルコンテナを生成し、アプリ全体で使う保存領域を準備する。
    init() {
        do {
            modelContainer = try ModelContainer(for: Thing.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    /// アプリのメインウィンドウを構成し、実データリポジトリをルート View に注入する。
    var body: some Scene {
        WindowGroup {
            AppRootView(
                repository: SwiftDataThingRepository(
                    modelContext: modelContainer.mainContext
                )
            )
        }
    }
}
