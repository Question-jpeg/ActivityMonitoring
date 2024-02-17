//
//  Suggestions.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 13.02.2024.
//

import Foundation

extension FirebaseConstants {
    static func getSendingSuggestions() async throws -> [Suggestion] {
        guard let currentUserId else { throw AuthError.unexpected }
        
        return try await getSendingSuggestionsCollectionRef(profileId: currentUserId).getDocuments().documents.compactMap { try? $0.data(as: Suggestion.self) }
    }
    
    static func createSuggestion(toUserId: String, config: AppTaskConfig) async throws -> Suggestion {
        guard let currentUserId else { throw AuthError.unexpected }
        let ref = getSendingSuggestionsCollectionRef(profileId: currentUserId).document()
        let gainRef = getGainingSuggestionsCollectionRef(profileId: toUserId).document(ref.documentID)
        
        let suggestion = Suggestion(id: ref.documentID, fromId: currentUserId, toId: toUserId, config: config, status: .pending, comment: "")
        let data = try encode(suggestion)
        
        let batch = firestore.batch()
        
        batch.setData(data, forDocument: ref)
        batch.setData(data, forDocument: gainRef)        
        
        try await batch.commit()
        
        return suggestion
    }
    
    static func removeSuggestion(toUserId: String, id: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let ref = getSendingSuggestionsCollectionRef(profileId: currentUserId).document(id)
        let gainRef = getGainingSuggestionsCollectionRef(profileId: toUserId).document(id)
        
        let batch = firestore.batch()
        
        batch.deleteDocument(ref)
        batch.deleteDocument(gainRef)
        
        try await batch.commit()
    }
    
    static func updateSuggestionStatus(fromUserId: String, id: String, status: SuggestionStatus, comment: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let ref = getSendingSuggestionsCollectionRef(profileId: fromUserId).document(id)
        let gainRef = getGainingSuggestionsCollectionRef(profileId: currentUserId).document(id)
        
        let batch = firestore.batch()
        
        batch.deleteDocument(gainRef)
        batch.updateData(try encode(SuggestionStatusUpdate(status: status, comment: comment)), forDocument: ref)
        
        try await batch.commit()
    }
}
