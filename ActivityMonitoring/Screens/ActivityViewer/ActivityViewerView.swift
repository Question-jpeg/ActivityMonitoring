//
//  ActivityViewerView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

struct ActivityViewerView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    
    @StateObject var completionModel: TaskCompletionViewModel
    
    @State private var scrollIndex = 7
    @State private var showingRating = false
    @State private var showingTomorrowTasks = false
    @State private var showingCreateTask = false
    
    var user: User?
    
    init(mainModel: MainViewModel, user: User?) {
        self.user = user
        _completionModel = StateObject(wrappedValue: TaskCompletionViewModel(mainModel: mainModel))
    }
    
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    
    func updateStartDate() {
        if Calendar.current.differenceInDays(from: startDate, to: Date()) != 7 {
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
    }
    
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
                map[index]?[configId] = $0
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
        TabView(selection: $scrollIndex) {
            let configsMap = getTaskConfigsMap()
            let tasksMap = getTasksMap()
            
            ForEach(0..<15, id: \.self) { i in
                let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
                let disabled = user != nil || i != 7
                DayView(date: date, configs: configsMap[i]!, tasksMap: tasksMap[i]!, disabled: disabled, isOwner: user == nil)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .top) {
            if let user {
                VStack(spacing: -20) {
                    Rectangle()
                        .fill(LinearGradient(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 60)
                    UserCell(user: user, isLink: false, isBack: true) {
                        dismiss()
                    }
                }
                .ignoresSafeArea()
            }
        }
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
                
                if user == nil {
                    Button {
                        showingCreateTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .padding(10)
                            .foregroundStyle(.white)
                            .background(themeModel.theme.tint)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }
        .onAppear {
            updateStartDate()
            
            if let user {
                mainModel.subscribeOn(profileId: user.id)
            }
        }
        .onChange(of: scenePhase) { _, _ in
            if scenePhase == .active { updateStartDate() }
        }
        .fullScreenCover(isPresented: $showingRating) {
            PlanView(showingSelf: $showingRating, user: user)
        }
        .sheet(isPresented: $showingTomorrowTasks, content: {
            let configs = getTomorrowTasks()
            VStack {
                if !configs.isEmpty {
                    VStack(spacing: 5) {
                        ForEach(0..<configs.count, id: \.self) { i in
                            TaskConfigInfoView(config: configs[i])
                            if i != configs.count - 1 {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                        }
                    }
                    .appCardStyle(colors: [themeModel.theme.accent1, themeModel.theme.accent2])
                } else {
                    Text("Нет особенных задач на завтра")
                        .appCardStyle(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
                }
            }
            .presentationDetents([.medium])
        })
        .fullScreenCover(isPresented: $showingCreateTask) {
            TaskConfigDetailsView(mainModel: mainModel, bottomPresenting: true)
        }
        .environmentObject(completionModel)
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
    
    let colors: [Color]
    let configs: [AppTaskConfig]
    let tasksMap: [String: AppTask]
    let unavailable: Bool
    let isOwner: Bool
    let cardHeight: Double
    
    @Binding var cardContentHeight: Double
    @State private var presentingConfig: AppTaskConfig?
    @State private var taskData: TaskCompletionData?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<(configs.count), id: \.self) { i in
                        let config = configs[i]
                        let completedTask = tasksMap[config.id]
                        
                        HStack(spacing: 0) {
                            if config.taskType == .tracker {
                                Button {
                                    let disabled = unavailable || config.isOutOfDate
                                    if let completedTask, !disabled {
                                        if completedTask.progress == 1 {
                                            completionModel.deleteTask(id: completedTask.id, configId: config.id, isSheet: false)
                                        } else {
                                            completionModel.setTaskProgress(
                                                id: completedTask.id, configId: config.id,
                                                from: completedTask.progress, value: completedTask.progress-1,
                                                fromComment: completedTask.comment, comment: completedTask.comment.lastLineDeleted,
                                                isSheet: false)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .padding([.top, .leading, .bottom])
                                        .contentShape(Rectangle())
                                }
                                .disabled((completedTask?.progress ?? 0) == 0)
                            }
                            
                            Button {
                                
                            } label: {
                                TaskConfigInfoView(config: config, checked: completedTask != nil, progress: completedTask?.progress ?? 0)
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(
                                        LongPressGesture()
                                            .onEnded { _ in
                                                if isOwner && !config.isHidden { presentingConfig = config }
                                            }
                                    )
                                    .highPriorityGesture(
                                        TapGesture()
                                            .onEnded {
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
                                            }
                                    )
                            }
                            
                            if config.taskType == .tracker {
                                Button {
                                    let disabled = unavailable || config.isOutOfDate
                                    if !disabled {
                                        if config.imageValidation {
                                            taskData = TaskCompletionData(selectedConfig: config, task: completedTask, editable: true)
                                        } else {
                                            if let completedTask {
                                                completionModel.setTaskProgress(
                                                    id: completedTask.id, configId: config.id,
                                                    from: completedTask.progress, value: completedTask.progress+1,
                                                    isSheet: false)
                                            } else {
                                                completionModel.createTask(configId: config.id, isSheet: false)
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .padding([.top, .trailing, .bottom])
                                        .contentShape(Rectangle())
                                }
                                .disabled((completedTask?.progress ?? 0) == config.maxProgress)
                            }
                        }
                        .disabled(completionModel.loadingIds.contains(config.id))
                        .opacity(config.imageValidation && completionModel.loadingIds.contains(config.id) ? 0.5 : 1)
                        
                        if i != configs.count - 1 {
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.vertical)
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { cardContentHeight = geo.size.height }
                            .onChange(of: configs) { _, _ in
                                cardContentHeight = geo.size.height
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .appCardStyle(colors: colors, paddingEdges: configs[0].taskType == .tracker ? [] : [.leading, .trailing])
        .fullScreenCover(item: $presentingConfig) { config in
            TaskConfigDetailsView(mainModel: mainModel, initialTaskConfig: config, bottomPresenting: true)
        }
        .fullScreenCover(item: $taskData) { data in
            TaskCompletionDetailsView(
                taskConfig: data.selectedConfig,
                task: data.task,
                editable: data.editable
            )
        }
    }
}

struct DayView: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let date: Date
    let configs: [AppTaskConfig]
    let tasksMap: [String: AppTask]
    let disabled: Bool
    let isOwner: Bool
    
    @State private var trackersContentHeight = 0.0
    @State private var goalsContentHeight = 0.0
    @State private var habitsContentHeight = 0.0
    
    func getHeights(cardMaxHeight: Double, totalMaxHeight: Double) -> (trackers: Double,  goals: Double, habits: Double) {
        /// calculate usual card heights
        let trackersCardHeight = min(cardMaxHeight, trackersContentHeight)
        let goalsCardHeight = min(cardMaxHeight, goalsContentHeight)
        let habitsCardHeight = min(cardMaxHeight, habitsContentHeight)
        
        var result = (trackers: trackersCardHeight, goals: goalsCardHeight, habits: habitsCardHeight)
        /// calculating the error (how much we can expand)
        var availableDiff = totalMaxHeight - (trackersCardHeight + goalsCardHeight + habitsCardHeight)
        
        /// if we need to expand habits or goals
        if (habitsContentHeight > cardMaxHeight) || (goalsContentHeight > cardMaxHeight) {
            if habitsContentHeight > cardMaxHeight {
                /// if we need to expand habits and goals
                if goalsContentHeight > cardMaxHeight {
                    let habitsTargetDiff = habitsContentHeight - cardMaxHeight
                    let goalsTargetDiff = goalsContentHeight - cardMaxHeight
                    var avaDiff = availableDiff / 2
                    if habitsTargetDiff < avaDiff || goalsTargetDiff < avaDiff {
                        if habitsTargetDiff < avaDiff {
                            /// no need to limit because of habitsTargetDiff is less than avaDiff
                            result.habits = habitsContentHeight
                            /// keep tracking the diff, so it is consistent
                            availableDiff -= result.habits - cardMaxHeight
                            /// adding the remainder
                            avaDiff += avaDiff - habitsTargetDiff
                            /// we are not sure if goalsTargetDiff is less than avaDiff, so we need to limit this to available diff expansion
                            result.goals = min(goalsContentHeight, cardMaxHeight+avaDiff)
                        } else {
                            result.goals = goalsContentHeight
                            availableDiff -= result.goals - cardMaxHeight
                            avaDiff += avaDiff - goalsTargetDiff
                            /// just copying the above one case
                            result.habits = min(habitsContentHeight, cardMaxHeight+avaDiff)
                        }
                    } else {
                        /// if both cards are too large, just equally expand them by all available diff
                        result.habits = cardMaxHeight+avaDiff
                        result.goals = cardMaxHeight+avaDiff
                        availableDiff = 0
                    }
                } else {
                    /// if we need to expand only habits
                    result.habits = min(habitsContentHeight, cardMaxHeight+availableDiff)
                    availableDiff -= result.habits - cardMaxHeight
                }
            } else {
                /// if we need to expand only goals
                result.goals = min(goalsContentHeight, cardMaxHeight+availableDiff)
                availableDiff -= result.goals - cardMaxHeight
            }
        }
        if (trackersContentHeight > cardMaxHeight) {
            /// expand trackers by remainder
            result.trackers = min(trackersContentHeight, cardMaxHeight+availableDiff)
        }
        
        return result
    }
    
    var body: some View {
        VStack {
            let trackers = configs.filter { $0.taskType == .tracker }
            let goals = configs.filter { $0.taskType == .goal }
            let habits = configs.filter { $0.taskType == .habit }
            
            if !configs.isEmpty {
                let scaleFactor = 1 / Double([trackers, goals, habits].filter { $0.count != 0 }.count)
                let totalMaxHeight = UIScreen.height*0.6
                let maxHeight = totalMaxHeight*scaleFactor
                let cardHeights = getHeights(cardMaxHeight: maxHeight, totalMaxHeight: totalMaxHeight)
                
                Text(date.toString())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 5) {
                    if !trackers.isEmpty {
                        TaskConfigsCardView(
                            colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                            configs: trackers, tasksMap: tasksMap,
                            unavailable: disabled,
                            isOwner: isOwner,
                            cardHeight: cardHeights.trackers,
                            cardContentHeight: $trackersContentHeight
                        )
                        .onDisappear { trackersContentHeight = 0 }
                    }
                    
                    if !goals.isEmpty {
                        TaskConfigsCardView(
                            colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                            configs: goals, tasksMap: tasksMap,
                            unavailable: disabled,
                            isOwner: isOwner,
                            cardHeight: cardHeights.goals,
                            cardContentHeight: $goalsContentHeight
                        )
                        .onDisappear { goalsContentHeight = 0 }
                    }
                    
                    if !habits.isEmpty {
                        TaskConfigsCardView(
                            colors: [themeModel.theme.accent1, themeModel.theme.accent2],
                            configs: habits, tasksMap: tasksMap,
                            unavailable: disabled,
                            isOwner: isOwner,
                            cardHeight: cardHeights.habits,
                            cardContentHeight: $habitsContentHeight
                        )
                        .onDisappear { habitsContentHeight = 0 }
                    }
                }
            } else {
                VStack {
                    Text("Нет активных задач")
                        .font(.title)
                    
                    Text(date.toString())
                }
                .foregroundStyle(.secondary)
            }
            
        }
        .padding(.horizontal)
    }
}
