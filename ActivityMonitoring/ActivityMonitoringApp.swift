//
//  ActivityMonitoringApp.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 07.02.2024.
//

import SwiftUI

import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct ActivityMonitoringApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authModel = AuthViewModel()
    @StateObject var themeModel = AppThemeModel()
    
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .systemPurple

        Task {
            do {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                // Handle the error here.
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authModel)
                .environmentObject(themeModel)
                .alert(item: $authModel.errorMessage) { errorMessage in
                    Alert(title: Text(errorMessage))
                }
                .preferredColorScheme(themeModel.colorScheme)
        }
    }
}
