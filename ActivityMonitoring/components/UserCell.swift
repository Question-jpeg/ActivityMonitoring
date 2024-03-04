//
//  UserView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI
import Kingfisher

struct UserCell: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let user: User
    var isLink = true
    var isBack = false
    var isBottomPresenting = false
    var onPress: () -> Void = {}
    
    @ViewBuilder
    func chevron(left: Bool) -> some View {
        Image(systemName: "chevron.\(left ? (isBottomPresenting ? "down" : "left") : "right").circle.fill")
            .font(.title)
            .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    func chevronComponent(left: Bool) -> some View {
        if left {
            if isBack {
                Button {
                    onPress()
                } label: {
                    chevron(left: left)
                }
            }
        } else if isLink {
            chevron(left: left)
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            HStack {
                chevronComponent(left: true)
                    .padding(.horizontal, 5)
                
                ProfileImageView(size: 25) {
                    if let imageUrl = user.imageUrl {
                        KFImage(URL(string: imageUrl))
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            Text(user.name)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            chevronComponent(left: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, -5)
        .appCardStyle(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
    }
}

#Preview {
    UserCell(user: MockData.user, isLink: false, isBack: true)
}
