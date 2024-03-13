//
//  String.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import Foundation

extension String: Identifiable {
    public var id: String {
        self
    }
    
    var lastLineDeleted: String {
        if let index = lastIndex(of: "\n") {
            let i = self.index(before: index)
            return String(self[...i])
        }
        return ""
    }
    
    func trimmedLineAppended(line: String) -> String {
        var suffix = "• " + line.trimmingCharacters(in: .whitespacesAndNewlines)
        if !isEmpty { suffix = "\n" + suffix }
        
        return self + suffix
    }
}
