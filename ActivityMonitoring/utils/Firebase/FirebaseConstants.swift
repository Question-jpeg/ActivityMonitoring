//
//  FirebaseConstants.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

enum AuthError: Error {
    case unexpected
}

enum UploadError: Error, LocalizedError {
    case noJpegData
    
    var errorDescription: String? {
        switch self {
        case .noJpegData:
            return "Unable to get jpeg data from image"
        }
    }
}

struct FirebaseConstants {
    static let firestore = Firestore.firestore()
    static let storage = Storage.storage()
    static let encoder = Firestore.Encoder()
    static let auth = Auth.auth()
    
    static let usersCollection = firestore.collection("users")
    static let profiles = firestore.collection("profiles")
    static let accesses = firestore.collection("accesses")
    static let suggestions = firestore.collection("suggestions")
    
    static var currentUserId: String? {
        auth.currentUser?.uid
    }
    
    static func encode(_ value: Encodable) throws -> [String: Any] {
        try encoder.encode(value)
    }
}
