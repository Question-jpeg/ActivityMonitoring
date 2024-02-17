//
//  RegistrationView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

enum RegistrationField {
    case name, email, password
}

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authModel: AuthViewModel
    
    @State private var image: UIImage?
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    @State private var showingImagePicker = false
    @FocusState private var focus: RegistrationField?
    
    var isValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Регистрация")
                    .font(.title)
                
                Button {
                    showingImagePicker = true
                } label: {
                    ProfileImageView {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                }
                
                Text("Загрузите фото профиля")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                    .opacity(image == nil ? 1 : 0)
                
                Button {
                    focus = .name
                } label: {
                    TextField("Имя", text: $name)
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }
                        .appTextField()
                }
                
                Button {
                    focus = .email
                } label: {
                    TextField("E-mail", text: $email)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .appTextField()
                        .strictFieldStyle()
                }
                
                Button {
                    focus = .password
                } label: {
                    SecureField("Пароль", text: $password)
                        .focused($focus, equals: .password)
                        .submitLabel(.continue)
                        .appTextField()
                        .strictFieldStyle()
                }
                
                AuthButton(
                    title: "Зарегистрироваться",
                    isLoading: authModel.loading
                ) {
                    if !isValid {
                        authModel.errorMessage = "Некорректное заполнение формы"
                    } else {
                        authModel.register(withEmail: email, password: password, name: name, image: image)
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Уже есть аккаунт? ")
                    +
                    Text("Авторизоваться")
                        .underline()
                }
                .padding(.top, 50)
            }
            .frame(height: UIScreen.height - 100)
            .padding(.horizontal)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $image)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthViewModel())
}
