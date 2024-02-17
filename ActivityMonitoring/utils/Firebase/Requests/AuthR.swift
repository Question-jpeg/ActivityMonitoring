//
//  Auth.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI

extension FirebaseConstants {
    static func registerUser(withEmail email: String, password: String, name: String, image: UIImage?) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        let id = result.user.uid
        var imageUrl: String? = nil
        
        if let image {
            do {
                imageUrl = try await uploadImage(id: id, image: image)
            } catch {}
        }
        
        let user = User(
            id: id,
            name: name,
            imageUrl: imageUrl
        )
        
        let batch = firestore.batch()
        batch.setData(try encode(user), forDocument: getUserDocRef(id))
        batch.setData(try encode(Profile(id: id)), forDocument: getProfileDocRef(id))
        
        do {
            try await batch.commit()
        } catch {
            try await auth.currentUser?.delete()
            try await storage.reference(withPath: id).delete()
            throw AuthError.unexpected
        }
        
        return user
    }
    
    static func logIn(withEmail email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        let id = result.user.uid
        do {
            return try await fetchUser(id)
        } catch {
            try auth.signOut()
            throw AuthError.unexpected
        }
    }
    
    static func logOut() throws {
        try auth.signOut()
    }
}
