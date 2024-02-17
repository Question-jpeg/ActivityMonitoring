//
//  AuthView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

enum AuthField {
    case email, password
}

struct AuthView: View {
    @EnvironmentObject var authModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focus: AuthField?
    
    var isValid: Bool {
        !email.isEmpty &&
        !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Авторизуйтесь")
                    .font(.title)
                
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
                    title: "Войти",
                    isLoading: authModel.loading
                ) {
                    if !isValid {
                        authModel.errorMessage = "Некорректное заполнение формы"
                    } else {
                        authModel.login(withEmail: email, password: password)
                    }
                }
                
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden()
                } label: {
                    Text("Нет аккаунта? ")
                    +
                    Text("Зарегистрироваться")
                        .underline()
                }
                .padding(.top, 50)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}

struct AuthButton: View {
    let title: String
    let isLoading: Bool
    let onPress: () -> Void
    
    var body: some View {
        Button {
            onPress()
        } label: {
            HStack {
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .overlay {
                if isLoading {
                    HStack {
                        ProgressView()
                        Spacer()
                        ProgressView()
                    }
                    .tint(.white)
                }
            }
            .appCardStyle(colors: isLoading ? [.gray, Color(.systemGray4)] : [.red, .orange])
        }
        .disabled(isLoading)
        .padding(.top)
    }
}
