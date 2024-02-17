//
//  ContentView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 07.02.2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authModel: AuthViewModel
    
    var body: some View {
        if !authModel.loadingAuth {
            if authModel.currentUser == nil {
                AuthView()
            } else {
                MainTabBar(authModel: authModel)
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
