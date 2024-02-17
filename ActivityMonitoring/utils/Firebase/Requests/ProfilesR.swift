//
//  Profiles.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Foundation

extension FirebaseConstants {
    static func grantUser(id: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let batch = firestore.batch()
        batch.setData(try encode(GrantedUser(id: id)), forDocument: getSharingDocRef(profileId: currentUserId, id: id))
        batch.setData(try encode(GrantedUser(id: currentUserId)), forDocument: getGainingDocRef(userId: id, profileId: currentUserId))
        try await batch.commit()
    }
    
    static func revokeSharing(id: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let batch = firestore.batch()
        
        batch.deleteDocument(getSharingDocRef(profileId: currentUserId, id: id))
        batch.deleteDocument(getGainingDocRef(userId: id, profileId: currentUserId))
        
        try await batch.commit()
    }
    
    static func getGrantedUsers() async throws -> [String] {
        guard let currentUserId else { throw AuthError.unexpected }
        let snapshot = try await getSharingCollection(profileId: currentUserId).getDocuments()
        return snapshot.documents.compactMap { (try? $0.data(as: GrantedUser.self))?.id }
    }
}
