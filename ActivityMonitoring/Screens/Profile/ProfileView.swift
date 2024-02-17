//
//  ProfileView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var authModel: AuthViewModel
    
    @State private var showingImagePicker = false
    @State private var image: UIImage?
    @State private var name = ""
    @FocusState private var focused: Bool
    
    @State private var loading = false
    
    var currentUser: User {
        authModel.currentUser ?? MockData.user
    }
    
    var hasChanged: Bool {
        !name.isEmpty && (image != nil || name != currentUser.name)
    }
    
    func revert() {
        image = nil
        name = currentUser.name
    }
    
    func updateUser() {
        loading = true
        Task { @MainActor in
            defer { loading = false }
            
            do {
                let update = try await FirebaseConstants.updateUser(id: currentUser.id, name: name, imageUrl: currentUser.imageUrl, image: image)
                authModel.currentUser = User(id: currentUser.id, name: update.name, imageUrl: update.imageUrl)
                image = nil
                name = update.name
            } catch {
                authModel.errorMessage = "Не удалось обновить данные пользователя"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 30) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        ProfileImageView {
                            if let image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else if let imageUrl = currentUser.imageUrl {
                                KFImage(URL(string: imageUrl))
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                    }
                    
                    Button {
                        focused = true
                    } label: {
                        TextField("Имя", text: $name)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .foregroundStyle(.foreground)
                            .focused($focused)
                            .appTextField()
                    }
                }
                .padding(10)
                .appCardStyle(colors: [Color(.systemGray), Color(.systemGray4)])
                .overlay(alignment: .top) {
                    if hasChanged && !loading {
                        HStack {
                            Button {
                                revert()
                            } label: {
                                Image(systemName: "x.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.title)
                            }
                            Spacer()
                            Button {
                                updateUser()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.title)
                                
                            }
                        }
                        .padding(20)
                    }
                    
                    if loading {
                        HStack {
                            Spacer()
                            ProgressView()
                        }
                        .tint(.white)
                        .padding(20)
                    }
                }
                .animation(.default, value: hasChanged)
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $image)
                }
                .onAppear { name = currentUser.name }
                
                let percentageData = mainModel.overallTasksCounts
                BatteryView(targetCount: percentageData.targetCount, completedCount: percentageData.completedCount, flex: true)
                    .padding(.top, -20)
                
                NavigationLink {
                    ThemeCustomizationView()
                        .navigationBarBackButtonHidden()
                } label: {
                    Text("Сменить тему")
                        .frame(maxWidth: .infinity)
                        .appCardStyle(colors: [Color(.systemGray), Color(.systemGray4)])
                }
                
                Button(role: .destructive) {
                    mainModel.unsubscribeAll()
                    authModel.logOut()
                } label: {
                    Text("Выйти")
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    let authModel = AuthViewModel()
    return ProfileView()
        .environmentObject(authModel)
        .environmentObject(MainViewModel(authModel: authModel))
}
