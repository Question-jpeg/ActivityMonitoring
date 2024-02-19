//
//  ActivityViewerView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

struct ActivityViewerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    
    @StateObject var completionModel: TaskCompletionViewModel
    
    @State private var scrollIndex = 7
    @State private var showingRating = false
    
    var user: User?
    
    init(mainModel: MainViewModel, user: User?) {
        self.user = user
        _completionModel = StateObject(wrappedValue: TaskCompletionViewModel(mainModel: mainModel))
    }
    
    let startDate = Calendar.current.date(
        byAdding: .day,
        value: -7,
        to: Date()
    )!
    
    func getTaskConfigsMap() -> [Int: [AppTaskConfig]] {
        let configs: [AppTaskConfig]
        var map = [Int: [AppTaskConfig]]()
        (0...14).forEach { map[$0] = [] }
        
        if user != nil {
            configs = mainModel.viewingTaskConfigs
        } else {
            configs = mainModel.taskConfigs
        }
        
        configs.sorted(by: { AppTaskConfig.sortFunction(config1: $0, config2: $1) }).forEach { config in
            let startIndex = max(0, Calendar.current.differenceInDays(from: startDate, to: config.startingFrom.dateValue()))
            let endIndex = config.completedDate == nil ? 14 :
            Calendar.current.differenceInDays(from: startDate, to: config.completedDate!.dateValue())
            
            let startDateWeekday = Calendar.current.component(.weekday, from: startDate)
            
            config.weekDays.forEach {
                var index = $0.value - startDateWeekday
                while true {
                    if index > endIndex {
                        break
                    }
                    if index >= startIndex {
                        map[index]?.append(config)
                    }
                    
                    index += 7
                }
            }
        }
        
        return map
    }
    
    func getTasksMap() -> [Int: [String: AppTask]] {
        let tasksMap: [String: [AppTask]]
        var map = [Int: [String: AppTask]]()
        (0...14).forEach { map[$0] = [:] }
        
        if user != nil {
            tasksMap = mainModel.renderViewingTasksMap
        } else {
            tasksMap = mainModel.renderTasksMap
        }
        tasksMap.keys.forEach { configId in
            tasksMap[configId]?.forEach {
                let index = Calendar.current.differenceInDays(from: startDate, to: $0.completedDate.dateValue())
                map[index]![configId] = $0
            }
        }
        
        return map
    }
    
    var body: some View {        
        ScrollView {
            VStack(spacing: 0) {
                let configsMap = getTaskConfigsMap()
                let tasksMap = getTasksMap()
                
                ForEach(0..<15, id: \.self) { i in
                    let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
                    
                    let goals = configsMap[i]!.filter({ $0.taskType == .goal })
                    let habits = configsMap[i]!.filter({ $0.taskType == .habit })
                    let disabled = user != nil || i != 7
                    
                    VStack {
                        if !configsMap[i]!.isEmpty {
                            Text(date.toString())
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 15) {
                                if !goals.isEmpty {
                                    TaskConfigsCardView(
                                        title: "Целевые задачи", colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                                        configs: goals, tasksMap: tasksMap[i]!,
                                        unavailable: disabled, biggerSize: habits.isEmpty
                                    )
                                }
                                if !habits.isEmpty {
                                    TaskConfigsCardView(
                                        title: "Привычки", colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2],
                                        configs: habits, tasksMap: tasksMap[i]!,
                                        unavailable: disabled, biggerSize: goals.isEmpty
                                    )
                                }
                            }
                            .padding(.bottom)
                            .environmentObject(completionModel)
                            
                        } else {
                            VStack {
                                Text("Нет активных задач")
                                    .font(.title)
                                
                                Text(date.toString())
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: UIScreen.height)
                    .padding(.horizontal)
                    .offset(y: CGFloat(-scrollIndex)*UIScreen.height)
                    .animation(.default, value: scrollIndex)
                }
            }
        }
        .scrollDisabled(true)
        .overlay(alignment: .top) {
            if let user {
                Rectangle()
                    .fill(LinearGradient(colors: [Color(.systemGray2), Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 100)
                    .overlay {
                        UserCell(user: user, isLink: false, isBack: true) {
                            dismiss()
                        }
                        .offset(y: 40)
                        
                    }
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            HStack {
                if user != nil {
                    Button {
                        showingRating = true
                    } label: {
                        Text("Рейтинг")
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(themeModel.theme.tint)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .tint(.white)
                }
                
                Spacer()
                
                Button {
                    scrollIndex -= 1
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(15)
                        .background(themeModel.theme.tint)
                        .clipShape(Circle())
                }
                .disabled(scrollIndex == 0)
                .opacity(scrollIndex == 0 ? 0.5 : 1)
                
                Button {
                    scrollIndex += 1
                } label: {
                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(15)
                        .background(themeModel.theme.tint)
                        .clipShape(Circle())
                }
                .disabled(scrollIndex == 14)
                .opacity(scrollIndex == 14 ? 0.5 : 1)
            }
            .padding()
        }
        .onAppear {
            if let user {
                mainModel.subscribeOn(profileId: user.id)
            }
        }
        .fullScreenCover(isPresented: $showingRating) {
            PlanView(showingSelf: $showingRating, user: user)
        }
    }
}

#Preview {
    let mainModel = MainViewModel(authModel: AuthViewModel())
    return ActivityViewerView(mainModel: mainModel, user: MockData.user)
        .environmentObject(mainModel)
}

struct TaskCompletionData: Identifiable {
    var id: String { selectedConfig.id }
    let selectedConfig: AppTaskConfig
    let task: AppTask?
    let editable: Bool
}

struct TaskConfigsCardView: View {
    @EnvironmentObject var completionModel: TaskCompletionViewModel
    
    let title: String
    let colors: [Color]
    let configs: [AppTaskConfig]
    let tasksMap: [String: AppTask]
    let unavailable: Bool
    let biggerSize: Bool
    
    @State private var taskData: TaskCompletionData?
    @State private var contentSize: CGSize = .zero
    
    func isOutOfDate(config: AppTaskConfig) -> Bool {
        var isOutOfDate = false
        if let endAppTime = config.endTime ?? config.time {
            let startDate = Calendar.current.date(bySettingHour: config.time!.hour, minute: config.time!.minute, second: 0, of: Date())!
            let endDate = Calendar.current.date(
                bySettingHour: endAppTime.hour, minute: endAppTime.minute, second: 0, of: Date())!
            let startSeconds = Date().timeIntervalSince1970 - startDate.timeIntervalSince1970
            let deadlineHours = (Date().timeIntervalSince1970 - endDate.timeIntervalSince1970) / 3600
            isOutOfDate = startSeconds < 0 || deadlineHours > 1
        }
        
        return isOutOfDate
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 5)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<(configs.count), id: \.self) { i in
                        let config = configs[i]
                        let completedTask = tasksMap[config.id]
                        let completedTaskId = completedTask?.id
                        
                        Button {
                            let disabled = unavailable || isOutOfDate(config: config)
                            if (config.imageValidation ? (completedTaskId != nil || !disabled) : !disabled) {
                                if config.imageValidation {
                                    taskData = TaskCompletionData(selectedConfig: config, task: completedTask, editable: !disabled)
                                } else {
                                    if let completedTaskId  {
                                        completionModel.deleteTask(id: completedTaskId, configId: config.id, isSheet: false)
                                    } else {
                                        completionModel.createTask(configId: config.id, isSheet: false)
                                    }
                                }
                            }
                        } label: {
                            TaskConfigInfoView(config: config, checked: completedTaskId != nil)
                        }
                        .disabled(completionModel.loadingIds.contains(config.id))
                        
                        if i != configs.count - 1 {
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                }
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { contentSize = geo.size }
                            .onChange(of: configs) { _, _ in
                                contentSize = geo.size
                            }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: min(contentSize.height, biggerSize ? 300 : 170))
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(colors: colors)
        .fullScreenCover(item: $taskData) { data in
            TaskCompletionDetailsView(
                taskConfig: data.selectedConfig,
                task: data.task,
                editable: data.editable
            )
        }
    }
}

struct TaskConfigInfoView: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let config: AppTaskConfig
    var showingTaskType: Bool = false
    var taskTypeSize = 30.0
    var checked: Bool? = nil
    var targetCount: Int? = nil
    var completedCount: Int? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            if let checked {
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
                    if config.imageValidation {
                        Image(systemName: config.onlyCommentBool ? "rectangle.and.pencil.and.ellipsis" : "photo.fill")
                    }
                    Text(config.title)
                        .multilineTextAlignment(.leading)
                        .font(.headline)
                        .fontWeight(.regular)
                }
                
                if !config.description.isEmpty {
                    Text(config.description)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
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
