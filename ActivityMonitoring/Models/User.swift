//
//  Usert.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import Foundation

struct UserUpdate: Codable {
    let name: String
    var imageUrl: String?
}

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let imageUrl: String?
}
