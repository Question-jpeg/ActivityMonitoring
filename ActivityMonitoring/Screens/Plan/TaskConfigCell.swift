//
//  TaskConfigView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

//let title: String
//let description: String
//let repeatInDays: Int
//let startingFrom: Date
//let completedDate: Date?
//let taskType: TaskType

struct TaskConfigCell: View {
    let taskConfig: AppTaskConfig
    let allTasksCount: Int
    let completedTasksCount: Int
    
    var body: some View {
        HStack {
            taskConfig.taskType.image
                .font(.system(size: 30))
                .foregroundStyle(.purple)
            
            TaskConfigInfoView(config: taskConfig)
            
            Spacer()
            
            if allTasksCount != 0 {
                VStack {
                    BatteryView(targetCount: allTasksCount, completedCount: completedTasksCount)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    TaskConfigCell(taskConfig: MockData.taskConfig, allTasksCount: 100, completedTasksCount: 70)
        .padding(.horizontal)
}
