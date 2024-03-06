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
    @State private var showingTomorrowTasks = false
    @State private var showingCreateTask = false
    @State private var taskData: TaskCompletionData?
    
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
    
    func getTomorrowTasks() -> [AppTaskConfig] {
        let configsMap = getTaskConfigsMap()
        let todayIds = Set(configsMap[7]!.map { $0.groupId })
        return configsMap[8]!.filter { !todayIds.contains($0.groupId) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let configsMap = getTaskConfigsMap()
                let tasksMap = getTasksMap()
                
                ForEach(0..<15, id: \.self) { i in
                    VStack {
                        if abs(scrollIndex - i) <= 1 {
                            let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
                            let disabled = user != nil || i != 7
                            let configs = configsMap[i]!
                            
                            let trackers = configs.filter { $0.taskType == .tracker }
                            let goals = configs.filter { $0.taskType == .goal }
                            let habits = configs.filter { $0.taskType == .habit }
                            
                            let scaleFactor = Double([trackers, goals, habits].filter { $0.count == 0 }.count + 1)
                            
                            if !configs.isEmpty {
                                Text(date.toString())
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 5) {
                                    if !trackers.isEmpty {
                                        TaskConfigsCardView(
                                            title: "Трекеры", colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                                            configs: trackers, tasksMap: tasksMap[i]!,
                                            unavailable: disabled,
                                            scaleFactor: scaleFactor,
                                            taskData: $taskData
                                        )
                                    }
                                    
                                    if !goals.isEmpty {
                                        TaskConfigsCardView(
                                            title: "Цели", colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                                            configs: goals, tasksMap: tasksMap[i]!,
                                            unavailable: disabled,
                                            scaleFactor: scaleFactor,
                                            taskData: $taskData
                                        )
                                    }
                                    
                                    if !habits.isEmpty {
                                        TaskConfigsCardView(
                                            title: "Привычки", colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                                            configs: habits, tasksMap: tasksMap[i]!,
                                            unavailable: disabled,
                                            scaleFactor: scaleFactor,
                                            taskData: $taskData
                                        )
                                    }
                                }
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
                    }
                    .frame(maxWidth: .infinity, minHeight: UIScreen.height)
                    .padding(.horizontal)
                    .offset(y: -30)
                }
            }
            .offset(y: Double(-scrollIndex)*UIScreen.height)
            .animation(.default, value: scrollIndex)
        }
        .scrollDisabled(true)
        .overlay(alignment: .top) {
            if let user {
                Rectangle()
                    .fill(LinearGradient(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2], startPoint: .leading, endPoint: .trailing))
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
            HStack(alignment: .bottom) {
                Button {
                    if user != nil {
                        showingRating = true
                    } else {
                        showingTomorrowTasks = true
                    }
                } label: {
                    Text(user != nil ? "Рейтинг" : "Задачи на завтра")
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(themeModel.theme.tint)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .tint(.white)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if user == nil {
                        Button {
                            showingCreateTask = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(15)
                                .background(themeModel.theme.tint)
                                .clipShape(Circle())
                        }
                    }
                    
                    HStack {
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
                }
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
        .sheet(isPresented: $showingTomorrowTasks, content: {
            let configs = getTomorrowTasks()
            VStack {
                if !configs.isEmpty {
                    ForEach(configs) {
                        TaskConfigInfoView(config: $0)
                            .appCardStyle(colors: [themeModel.theme.accent1, themeModel.theme.accent2])
                    }
                } else {
                    Text("Нет особенных задач на завтра")
                        .appCardStyle(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
                }
            }
            .presentationDetents([.medium])
        })
        .fullScreenCover(item: $taskData) { data in
            TaskCompletionDetailsView(
                taskConfig: data.selectedConfig,
                task: data.task,
                editable: data.editable
            )
            .environmentObject(completionModel)
        }
        .fullScreenCover(isPresented: $showingCreateTask) {
            TaskConfigDetailsView(mainModel: mainModel, bottomPresenting: true)
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
    @EnvironmentObject var mainModel: MainViewModel
    
    let title: String
    let colors: [Color]
    let configs: [AppTaskConfig]
    let tasksMap: [String: AppTask]
    let unavailable: Bool
    let scaleFactor: Double
    
    @State private var contentSize: CGSize = .zero
    @State private var presentingConfig: AppTaskConfig?
    @Binding var taskData: TaskCompletionData?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<(configs.count), id: \.self) { i in
                        let config = configs[i]
                        let completedTask = tasksMap[config.id]
                        
                        HStack {
                            if config.taskType == .tracker {
                                Button {
                                    let disabled = unavailable || config.isOutOfDate
                                    if let completedTask, !disabled {
                                        completionModel.setTaskProgress(
                                            id: completedTask.id, configId: config.id,
                                            from: completedTask.progress, value: completedTask.progress-1)
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .padding(10)
                                }
                                .disabled((completedTask?.progress ?? 0) == 0)
                            }
                            
                            Button {
                                let disabled = unavailable || config.isOutOfDate || config.taskType == .tracker
                                if (config.imageValidation ? (completedTask != nil || !disabled) : !disabled) {
                                    if config.imageValidation {
                                        taskData = TaskCompletionData(selectedConfig: config, task: completedTask, editable: !disabled)
                                    } else {
                                        if let completedTask  {
                                            completionModel.deleteTask(id: completedTask.id, configId: config.id, isSheet: false)
                                        } else {
                                            completionModel.createTask(configId: config.id, isSheet: false)
                                        }
                                    }
                                }
                            } label: {
                                TaskConfigInfoView(config: config, checked: completedTask != nil, progress: completedTask?.progress ?? 0)
                            }
                            
                            if config.taskType == .tracker {
                                Button {
                                    let disabled = unavailable || config.isOutOfDate
                                    if !disabled {
                                        if let completedTask {
                                            completionModel.setTaskProgress(
                                                id: completedTask.id, configId: config.id,
                                                from: completedTask.progress, value: completedTask.progress+1)
                                        } else {
                                            completionModel.createTask(configId: config.id, isSheet: false)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .padding(10)
                                }
                                .disabled((completedTask?.progress ?? 0) == config.maxProgress)
                            }
                        }
                        .disabled(completionModel.loadingIds.contains(config.id))
                        .simultaneousGesture(
                            LongPressGesture()
                                .onEnded { _ in
                                    presentingConfig = config
                                }
                        )
                        
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
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(height: min(contentSize.height, UIScreen.height/6*scaleFactor))
        .frame(maxWidth: .infinity)
        .appCardStyle(colors: colors)
        .fullScreenCover(item: $presentingConfig) { config in
            TaskConfigDetailsView(mainModel: mainModel, initialTaskConfig: config, bottomPresenting: true)
        }
    }
}
