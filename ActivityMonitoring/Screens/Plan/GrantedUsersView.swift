//
//  GrantedUsersView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI

struct GrantedUsersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    var assignConfig: AppTaskConfig? = nil
    
    var suggestions: [Suggestion] {
        if let assignConfig {
            return mainModel.sentSuggestions.filter { $0.config.id == assignConfig.id }
        }
        
        return []
    }
    
    var filteredUsers: [User] {
        mainModel.usersMap.values.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) &&
            !(
                assignConfig == nil ?
                mainModel.sharingUsers.contains { user.id == $0 } :
                suggestions.contains(where: { user.id == $0.toId })
            ) &&
            user.id != FirebaseConstants.currentUserId
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Готово")
                    }
                    .tint(themeModel.theme.tint)
                }
                
                Text(assignConfig != nil ? "Назначить задачу" : "Делиться планами с")
                    .font(.title)
            }
            
            Button {
                isFocused = true
            } label: {
                TextField("Начните вводить имя", text: $searchText)
                    .focused($isFocused)
                    .appTextField()
            }
            ScrollView {
                VStack {
                    Divider()
                    
                    ScrollView(.horizontal) {
                        HStack {
                            if assignConfig == nil {
                                ForEach(mainModel.usersWhoCanView) { user in
                                    let isLoading = mainModel.loadingId == user.id
                                    Button {
                                        mainModel.revokeSharing(id: user.id)
                                    } label: {
                                        GrantedUserCell(user: user)
                                            .opacity(isLoading ? 0.5 : 1)
                                            .overlay {
                                                if isLoading {
                                                    ProgressView()
                                                }
                                            }
                                    }
                                    .disabled(isLoading)
                                }
                            } else {
                                ForEach(suggestions) { suggestion in
                                    let isLoading = mainModel.loadingId == suggestion.id
                                    Button {
                                        mainModel.removeSuggestion(suggestion)
                                    } label: {
                                        GrantedUserCell(user: mainModel.usersMap[suggestion.toId]!)
                                            .opacity(isLoading ? 0.5 : 1)
                                            .overlay {
                                                if isLoading {
                                                    ProgressView()
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    
                    Divider()
                }
                
                
                VStack {
                    ForEach(filteredUsers) { user in
                        let isLoading = mainModel.loadingId == user.id
                        Button {
                            if let assignConfig {
                                mainModel.suggest(config: assignConfig, toId: user.id)
                            } else {
                                mainModel.grantUser(id: user.id)
                            }
                        } label: {
                            UserCell(user: user, isLink: false)
                                .opacity(isLoading ? 0.5 : 1)
                                .overlay {
                                    if isLoading {
                                        ProgressView()
                                    }
                                }
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
        }
        .tint(.primary)
        .padding(.horizontal)
        .alert(item: $mainModel.errorMessage) { errorMessage in
            Alert(title: Text(errorMessage))
        }
        .onAppear { isFocused = true }
    }
}

#Preview {
    GrantedUsersView()
        .environmentObject(MainViewModel(authModel: AuthViewModel()))
}
