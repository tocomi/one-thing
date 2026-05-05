//
//  one_thingApp.swift
//  one-thing
//
//  Created by Kenta TSUNEMI on 2026/05/05.
//

import SwiftUI
import SwiftData

@main
struct one_thingApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Thing.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

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
