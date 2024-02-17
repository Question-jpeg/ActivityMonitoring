//
//  Users.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func getUserDocRef(_ id: String? = nil) -> DocumentReference {
        if let id {
            return usersCollection.document(id)
        }
        return usersCollection.document()
    }
}
