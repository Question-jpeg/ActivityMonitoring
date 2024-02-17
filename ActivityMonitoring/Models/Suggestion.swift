//
//  Suggestion.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 13.02.2024.
//

import Foundation

enum SuggestionStatus: Int, Codable {
    case pending, declined, accepted
}

struct SuggestionStatusUpdate: Codable {
    let status: SuggestionStatus
    let comment: String
}

struct Suggestion: Identifiable, Codable {
    let id: String
    let fromId: String
    let toId: String
    let config: AppTaskConfig
    var status: SuggestionStatus
    var comment: String
    
    var renderUserId: String {
        FirebaseConstants.currentUserId == fromId ? toId : fromId
    }
    
    var isSending: Bool {
        FirebaseConstants.currentUserId == fromId
    }
}
