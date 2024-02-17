//
//  SuggestionsC.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 13.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func getSendingSuggestionsCollectionRef(profileId: String) -> CollectionReference {
        return suggestions.document(profileId).collection("sending")
    }
    
    static func getGainingSuggestionsCollectionRef(profileId: String) -> CollectionReference {
        return suggestions.document(profileId).collection("gaining")
    }
    
    static func getSendingSuggestionsQuery() throws -> Query {
        guard let currentUserId else { throw AuthError.unexpected }
        return getSendingSuggestionsCollectionRef(profileId: currentUserId)
    }
    
    static func getGainingSuggestionsQuery() throws -> Query {
        guard let currentUserId else { throw AuthError.unexpected }
        return getGainingSuggestionsCollectionRef(profileId: currentUserId)
    }
}
