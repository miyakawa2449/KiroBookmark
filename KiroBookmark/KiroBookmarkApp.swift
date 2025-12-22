//
//  KiroBookmarkApp.swift
//  KiroBookmark
//
//  Created by Tsuyoshi Miyakawa on 2025/12/22.
//

import SwiftUI

@main
struct KiroBookmarkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.viewContext
                )
        }
    }
}
