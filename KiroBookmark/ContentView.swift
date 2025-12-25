//
//  ContentView.swift
//  KiroBookmark
//
//  Created by Tsuyoshi Miyakawa on 2025/12/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
