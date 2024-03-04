//
//  GrantedUserCell.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI
import Kingfisher

struct GrantedUserCell: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let user: User
    
    var body: some View {
        VStack(spacing: 10) {
            ProfileImageView(size: 30) {
                if let imageUrl = user.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                }
            }
            
            Text(user.name)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(LinearGradient(
            colors: [
                themeModel.theme.secAccent1,
                themeModel.theme.secAccent2
            ],
            startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "x.circle.fill")
                .font(.title2)
                .padding(-6)
        }
    }
}

#Preview {
    GrantedUserCell(user: MockData.user)
}
