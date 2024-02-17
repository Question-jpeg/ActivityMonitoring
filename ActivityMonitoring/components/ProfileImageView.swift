//
//  ProfileImageView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

struct ProfileImageView<Overlay: View>: View {
    var size: CGFloat = 50
    @ViewBuilder let overlay: Overlay
    
    var body: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .padding(size*0.6)
            .background(Color(.systemGray5))
            .foregroundStyle(.gray)
            .overlay { overlay }
            .clipShape(Circle())
    }
}

#Preview {
    ProfileImageView {
    }
}
