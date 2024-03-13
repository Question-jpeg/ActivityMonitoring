//
//  ProfilesListView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI

struct ProfilesListView: View {
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    @State private var showingGrantedUsers = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(mainModel.availableProfiles) { user in
                        NavigationLink {
                            ActivityViewerView(mainModel: mainModel, user: user)
                                .navigationBarBackButtonHidden()
                        } label: {
                            UserCell(user: user)
                        }
                    }
                    
                    if mainModel.availableProfiles.isEmpty {
                        Text("С вами ещё никто не делится своими планами")
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .appCardStyle(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
                            .frame(height: UIScreen.height - 300)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Мониторинг")
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showingGrantedUsers = true
                } label: {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(15)
                        .background(themeModel.theme.tint)
                        .clipShape(Circle())
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showingGrantedUsers) {
                GrantedUsersView()
            }
        }
    }
}

#Preview {
    ProfilesListView()
        .environmentObject(MainViewModel(authModel: AuthViewModel()))
}
