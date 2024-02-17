//
//  Profiles.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func getProfileDocRef(_ id: String) -> DocumentReference {
        profiles.document(id)
    }
    
    static func getSharingDocRef(profileId: String, id: String) -> DocumentReference {
        getSharingCollection(profileId: profileId).document(id)
    }
    
    static func getGainingDocRef(userId: String, profileId: String) -> DocumentReference {
        getGainingCollection(profileId: userId).document(profileId)
    }
}
