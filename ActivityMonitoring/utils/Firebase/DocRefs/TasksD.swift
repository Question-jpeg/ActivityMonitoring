//
//  Tasks.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func getTaskConfigDocRef(profileId: String, id: String? = nil) -> DocumentReference {
        let collectionRef = getTaskConfigsCollectionRef(profileId: profileId)
        if let id { return collectionRef.document(id) }
        return collectionRef.document()
    }
    
    static func getTaskDocRef(profileId: String, configId: String, id: String? = nil) -> DocumentReference {
        let collectionRef = getTasksCollectionRef(profileId: profileId, configId: configId)
        if let id {
            return collectionRef.document(id)
        }
        return collectionRef.document()
    }
}
