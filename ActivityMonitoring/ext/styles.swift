//
//  styles.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 07.02.2024.
//

import SwiftUI

extension View {
    func appCardStyle(colors: [Color]) -> some View {
        self
            .padding()
            .background(LinearGradient(gradient: .init(colors: colors), startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(.white)
    }
    
    func appTextField() -> some View {
        self
            .multilineTextAlignment(.leading)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    func strictFieldStyle() -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
}
