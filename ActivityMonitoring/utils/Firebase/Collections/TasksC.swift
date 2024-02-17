//
//  Tasks.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func getTaskConfigsCollectionRef(profileId: String) -> CollectionReference {
        getProfileDocRef(profileId).collection("configs")
    }
    
    static func getTasksCollectionRef(profileId: String, configId: String) -> CollectionReference {
        getTaskConfigsCollectionRef(profileId: profileId).document(configId).collection("tasks")
    }
    
    static func getTaskConfigsQuery(profileId: String) -> Query {
        getTaskConfigsCollectionRef(profileId: profileId)
    }
    
    static func getTasksQuery(profileId: String, configId: String) -> Query {
        getTasksCollectionRef(profileId: profileId, configId: configId)
    }
}
