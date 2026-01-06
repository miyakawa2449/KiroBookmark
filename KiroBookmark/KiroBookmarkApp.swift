//
//  KiroBookmarkApp.swift
//  KiroBookmark
//
//  Created by Tsuyoshi Miyakawa on 2025/12/22.
//

import SwiftUI
import BackgroundTasks

@main
struct KiroBookmarkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    private let backgroundRefreshService = BackgroundRefreshService()
    private let notificationService = NotificationService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background tasks
        backgroundRefreshService.registerBackgroundTask()

        // Request notification authorization
        Task {
            _ = await notificationService.requestAuthorization()
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        backgroundRefreshService.scheduleAppRefresh()
    }
}
