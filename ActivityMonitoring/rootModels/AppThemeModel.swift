//
//  AppThemeModel.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 16.02.2024.
//

import SwiftUI

class AppThemeModel: ObservableObject {
    
    @Published var colorScheme: ColorScheme
    @Published var theme = AppTheme()
    @Published var currentTheme = AppTheme()
    
    var hasChanged: Bool {
        theme != currentTheme
    }
    
    var hasInMemory: Bool {
        if let savedTheme = UserDefaults.standard.object(forKey: "theme") as? Data,
        let _ = try? JSONDecoder().decode(AppTheme.self, from: savedTheme)
        { return true }
        return false
    }
    
    init() {
        switch UserDefaults.standard.object(forKey: "colorScheme") as? String ?? "" {
        case "light":
            colorScheme = .light
        default:
            colorScheme = .dark
        }
        
        setTheme()
    }
    
    func setTheme() {
        if let savedTheme = UserDefaults.standard.object(forKey: "theme") as? Data,
        let decodedTheme = try? JSONDecoder().decode(AppTheme.self, from: savedTheme)
        {
            currentTheme = decodedTheme
            theme = currentTheme
        }
    }
    
    func revertTheme() {
        theme = currentTheme
    }
    
    func saveTheme() {
        currentTheme = theme
        UserDefaults.standard.set(try! JSONEncoder().encode(theme), forKey: "theme")
    }
    
    func resetTheme() {
        currentTheme = AppTheme()
        theme = AppTheme()
        UserDefaults.standard.removeObject(forKey: "theme")
    }
    
    func toggleColorScheme() {
        let value: String
        switch colorScheme {
        case .light:
            colorScheme = .dark
            value = "dark"
        default:
            colorScheme = .light
            value = "light"
        }
        UserDefaults.standard.set(value, forKey: "colorScheme")
    }
}
