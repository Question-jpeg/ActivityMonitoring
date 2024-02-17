//
//  Users.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI

extension FirebaseConstants {
    static func getUsers() async throws -> [User] {
        let snapshot = try await usersCollection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
    
    static func fetchUser(_ id: String) async throws -> User {
        try await getUserDocRef(id).getDocument(as: User.self)
    }
    
    static func updateUser(id: String, name: String, imageUrl: String?, image: UIImage?) async throws -> UserUpdate {
        var update = UserUpdate(name: name, imageUrl: imageUrl)
        if let image {
            update.imageUrl = try await uploadImage(id: id, image: image)
        }
        
        let userDocRef = getUserDocRef(id)
        try await userDocRef.updateData(try encode(update))
        
        return update
    }
    
    static func uploadImage(id: String, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { throw UploadError.noJpegData }
        
        let ref = storage.reference(withPath: id)
        
        let _ = try await ref.putDataAsync(imageData)
        
        return (try await ref.downloadURL()).absoluteString
    }
    
    static func deleteImage(url: String) {
        Task {
            try? await storage.reference(forURL: url).delete()                
        }
    }
}
