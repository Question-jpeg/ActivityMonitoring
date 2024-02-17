//
//  SuggestionCell.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 13.02.2024.
//

import SwiftUI
import Kingfisher

struct SuggestionCell: View {
    @EnvironmentObject var themeModel: AppThemeModel
    @EnvironmentObject var mainModel: MainViewModel
    let suggestion: Suggestion
    
    var isShowingBell = false
    var bellState = false
    var onBellPress: () -> Void = {}
    
    var user: User {
        mainModel.usersMap[suggestion.renderUserId] ?? MockData.user
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ProfileImageView(size: 30) {
                if let imageUrl = user.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        if suggestion.isSending {
                            Text("Вы предлагаете задачу")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text(user.name)
                            .multilineTextAlignment(.leading)
                        
                        if !suggestion.isSending {
                            Text("Предлагает вам задачу")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if suggestion.status != .pending {
                        Image(systemName: suggestion.status == .declined ? "xmark.circle" : "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(suggestion.status == .declined ? .red : .green)
                    }
                }
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
                
                HStack {
                    TaskConfigInfoView(config: suggestion.config, showingTaskType: true, taskTypeSize: 20)
                    
                    if isShowingBell {
                        Button {
                            onBellPress()
                        } label: {
                            Image(systemName: bellState ? "bell.fill" : "bell")
                                .font(.title2)
                                .foregroundStyle(bellState ? themeModel.theme.tint : .secondary)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SuggestionCell(
        suggestion: Suggestion(
            id: UUID().uuidString,
            fromId: UUID().uuidString,
            toId: UUID().uuidString,
            config: MockData.taskConfig3,
            status: .pending,
            comment: "")
    )
    .padding(.horizontal)
    .environmentObject(MainViewModel(authModel: AuthViewModel()))
}
