//
//  Sequence.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Foundation

extension Sequence {
    func asyncCompactMap<T>(
            _ transform: (Element) async throws -> T?
        ) async throws -> [T] {
            var values = [T]()

            for element in self {
                guard let transformed = try await transform(element) else { continue }
                values.append(transformed)
            }

            return values
        }
    
    func asyncForEach(_ body: (Element) async throws -> Void) async {
        for element in self {
            try? await body(element)
        }
    }
}
