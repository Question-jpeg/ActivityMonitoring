//
//  TaskConfigInfoView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 03.03.2024.
//

import SwiftUI

struct TaskConfigInfoView: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let config: AppTaskConfig
    var showingTaskType: Bool = false
    var taskTypeSize = 30.0
    var checked: Bool? = nil
    var progress: Int? = nil
    var targetCount: Int? = nil
    var completedCount: Int? = nil
    
    var boltImage: Text {
        if config.isMomental {
            Text(Image(systemName: "bolt.fill"))
        } else {
            Text("")
        }
    }
    
    var photoImage: Text {
        if config.imageValidation {
            Text(Image(systemName: config.onlyComment ? "rectangle.and.pencil.and.ellipsis" : "photo.fill"))
        } else {
            Text("")
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if let checked, config.taskType != .tracker {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
            }
            
            if showingTaskType {
                config.taskType.image
                    .font(.system(size: taskTypeSize))
                    .foregroundStyle(themeModel.theme.tint)
            }
            
            VStack(spacing: 0) {
                Text(config.getTimeString())
                if config.endTime != nil {
                    Text(config.getEndTimeString())
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Group {
                        boltImage
                        +
                        photoImage
                        +
                        Text(config.title)
                    }
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 16).leading(.tight))
                }
                
                if let progress, config.taskType == .tracker {
                    HStack(spacing: 0) {
                        ForEach(1...config.maxProgress, id: \.self) { i in
                            Image(systemName: i <= progress ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(.white)
                            if i == config.edgeProgress {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 2, height: 25)
                                    .padding(.horizontal, 2)
                            }
                        }
                    }
                }
                
                if !config.description.isEmpty {
                    Text(config.description)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .font(.footnote.leading(.tight))
                }
            }
            Spacer()
            
            if let targetCount, let completedCount, targetCount != 0 {
                VStack {
                    BatteryView(targetCount: targetCount, completedCount: completedCount)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    TaskConfigInfoView(config: MockData.taskConfig, progress: 5)
        .environmentObject(AppThemeModel())
}
