//
//  AuthViewModel.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var loadingAuth = true
    @Published var loading = false
    
    init() {
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        Task {
            defer { loadingAuth = false }
            
            do {
                guard let currentUserId = FirebaseConstants.currentUserId else { return }
                currentUser = try await FirebaseConstants.fetchUser(currentUserId)
            } catch {
                errorMessage = "Не получилось войти"
            }
        }
    }
    
    func login(withEmail email: String, password: String) {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                currentUser = try await FirebaseConstants.logIn(withEmail: email, password: password)
            } catch {
                errorMessage = "Не удалось войти"
            }
        }
    }
    
    func register(withEmail email: String, password: String, name: String, image: UIImage?) {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                currentUser = try await FirebaseConstants.registerUser(withEmail: email, password: password, name: name, image: image)
            } catch {
                errorMessage = "Не удалось зарегистрироваться"
            }
        }
    }
    
    func logOut() {
        do {
            try FirebaseConstants.logOut()
            currentUser = nil
        } catch {
            errorMessage = "Не удалось выйти"
        }
    }
}
