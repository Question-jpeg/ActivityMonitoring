//
//  Profiles.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func getProfilesQuery() throws -> Query {
        guard let currentUserId else { throw AuthError.unexpected }
        return getGainingCollection(profileId: currentUserId)
    }
    
    static func getSharingCollection(profileId: String) -> CollectionReference {
        accesses.document(profileId).collection("sharing")
    }
    
    static func getGainingCollection(profileId: String) -> CollectionReference {
        accesses.document(profileId).collection("gaining")
    }
}
