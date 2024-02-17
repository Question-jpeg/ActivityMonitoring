//
//  MainTabBar.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

enum Tab {
    case sharing, tasks, editTasks, profile, suggestions
}

struct MainTabBar: View {
    @State private var selectedTab = Tab.tasks
    @StateObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    
    init(authModel: AuthViewModel) {
        _mainModel = StateObject(wrappedValue: MainViewModel(authModel: authModel))
    }
    
    var body: some View {
        if !mainModel.loading {
            TabView(selection: $selectedTab) {
                ProfilesListView()
                    .tabItem {
                        Label("Мониторинг", systemImage: "eye")
                            .environment(\.symbolVariants, selectedTab == .sharing ? .fill : .none)
                    }
                    .tag(Tab.sharing)
                
                ActivityViewerView(mainModel: mainModel, user: nil)
                    .tabItem {
                        Label("Задачи", systemImage: "list.clipboard")
                            .environment(\.symbolVariants, selectedTab == .tasks ? .fill : .none)
                    }
                    .tag(Tab.tasks)
                
                PlanView(showingSelf: .constant(true), user: nil)
                    .tabItem {
                        Label("План", systemImage: "pencil.circle")
                            .environment(\.symbolVariants, selectedTab == .editTasks ? .fill : .none)
                    }
                    .tag(Tab.editTasks)
                
                SuggestionsListView()
                    .tabItem {
                        Label("Предложения", systemImage: "doc.questionmark")
                            .environment(\.symbolVariants, selectedTab == .suggestions ? .fill : .none)
                    }
                    .tag(Tab.suggestions)
                    .badge(mainModel.gainingSuggestions.count + mainModel.sentSuggestions.filter { $0.status != .pending }.count)
                
                ProfileView()
                    .tabItem {
                        Label("Профиль", systemImage: "person")
                            .environment(\.symbolVariants, selectedTab == .profile ? .fill : .none)
                    }
                    .tag(Tab.profile)
            }
            .tint(themeModel.theme.tint)
            .environmentObject(mainModel)
        } else {
            ProgressView()
        }
    }
}

#Preview {
    MainTabBar(authModel: AuthViewModel())
}
