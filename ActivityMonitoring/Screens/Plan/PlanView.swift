//
//  PlanView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

struct PlanViewNavValue: Identifiable, Hashable {
    let id = UUID()
}

struct PlanView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    
    @State private var creatingNewTask = false
    @State private var addingPersons = false
    @State private var currentTabIndex = 0
    @Binding var showingSelf: Bool
    
    var isFinished = false
    let user: User?
    
    var taskConfigs: [AppTaskConfig] {
        return (isFinished ?
                allConfigs.filter { $0.isCompleted  } :
                allConfigs.filter { !$0.isCompleted }
        ).sorted(by: { AppTaskConfig.sortFunction(config1: $0, config2: $1) })
    }
    
    var allConfigs: [AppTaskConfig] {
        (user == nil ? mainModel.taskConfigs : mainModel.viewingTaskConfigs).filter { !$0.isHidden }
    }
    
    var tasksMap: [String: [AppTask]] {
        user == nil ? mainModel.tasksMap : mainModel.viewingTasksMap
    }
    
    var ratingMap: [String: (Int, Int)] {
        user == nil ? mainModel.tasksCountsMap : mainModel.viewingTasksCountsMap
    }
    
    var overallRating: (Int, Int) {
        user == nil ? mainModel.overallTasksCounts : mainModel.viewingOverallTasksCounts
    }
    
    @ViewBuilder
    func navDuplicateControl(left: Bool) -> some View {
        Group {
            if !isFinished {
                HStack(spacing: 0) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .opacity(left ? 0 : 1)
            } else {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .opacity(left ? 1 : 0)
            }
        }
        .foregroundStyle(themeModel.theme.tint)
    }
    
    @ViewBuilder var content: some View {
        VStack {
            if let user {
                Rectangle()
                    .fill(LinearGradient(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 100)
                    .overlay {
                        UserCell(user: user, isLink: false, isBack: true, isBottomPresenting: true) {
                            showingSelf = false
                        }
                        .overlay(alignment: .trailing) {
                            let (targetCount, completedCount) = overallRating
                            
                            BatteryView(targetCount: targetCount, completedCount: completedCount)
                                .padding(.trailing)
                        }
                        .offset(y: 40)
                    }
                    .ignoresSafeArea()
            }
            HStack {
                Button {
                    dismiss()
                } label: {
                    navDuplicateControl(left: true)
                }
                .disabled(!isFinished)
                
                Spacer()
                
                Text(isFinished ? "Завершённые задачи" : "Активные задачи")
                    .font(.title)
                
                Spacer()
                
                NavigationLink(value: PlanViewNavValue()) {
                    navDuplicateControl(left: false)
                }
                .disabled(isFinished)
            }
            .padding(.horizontal)
            .padding(.top, user == nil ? 15 : -20)
            
            HStack {
                Button {
                    withAnimation(.default) {
                        currentTabIndex = 0
                    }
                } label: {
                    TaskType.goal.image
                        .foregroundStyle(currentTabIndex == 0 ? themeModel.theme.tint : .gray)
                        .overlay(alignment: .bottom) {
                            if currentTabIndex == 0 {
                                Rectangle()
                                    .fill(.secondary)
                                    .frame(height: 1)
                                    .offset(y: 5)
                            }
                        }
                }
                
                Button {
                    withAnimation(.default) {
                        currentTabIndex = 1
                    }
                } label: {
                    TaskType.habit.image
                        .foregroundStyle(currentTabIndex == 1 ? themeModel.theme.tint : .gray)
                        .overlay(alignment: .bottom) {
                            if currentTabIndex == 1 {
                                Rectangle()
                                    .fill(.secondary)
                                    .frame(height: 1)
                                    .offset(y: 5)
                            }
                        }
                }
            }
            .tint(.primary)
            .padding(.top, 1)
            .padding(.bottom)
            .animation(.default, value: currentTabIndex)
            
            TabView(selection: $currentTabIndex) {
                TaskListView(
                    taskConfigs: taskConfigs.filter { $0.taskType == .goal },
                    tasksCountsMap: ratingMap,
                    isFinished: isFinished,
                    creatingNewTask: $creatingNewTask,
                    disabled: user != nil
                )
                .tag(0)
                TaskListView(
                    taskConfigs: taskConfigs.filter { $0.taskType != .goal },
                    tasksCountsMap: ratingMap,
                    isFinished: isFinished,
                    creatingNewTask: $creatingNewTask,
                    disabled: user != nil
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .overlay(alignment: .bottom) {
            if !isFinished && user == nil {
                HStack {
                    Button {
                        addingPersons = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(20)
                            .background(themeModel.theme.tint)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button {
                        creatingNewTask = true
                    } label: {
                        Image(systemName: "note.text.badge.plus")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(20)
                            .background(themeModel.theme.tint)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
        }
        .fullScreenCover(isPresented: $creatingNewTask) {
            TaskConfigDetailsView(mainModel: mainModel, bottomPresenting: true)
        }
        .sheet(isPresented: $addingPersons) {
            GrantedUsersView()
                .padding(.top, 30)
                .background(themeModel.colorScheme == .dark ? .black : .white)
        }
    }
    
    
    var body: some View {
        if !isFinished {
            NavigationStack {
                content
                    .navigationDestination(for: AppTaskConfig.self) { taskConfig in
                        TaskConfigDetailsView(mainModel: mainModel, initialTaskConfig: taskConfig)
                            .navigationBarBackButtonHidden()
                    }
                    .navigationDestination(for: PlanViewNavValue.self) { _ in
                        PlanView(showingSelf: $showingSelf, isFinished: true, user: user)
                            .navigationBarBackButtonHidden()
                    }
            }
        } else {
            content
        }
    }
}

#Preview {
    return PlanView(showingSelf: .constant(true), user: nil)
        .environmentObject(MainViewModel(authModel: AuthViewModel()))
}

struct TaskListView: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let taskConfigs: [AppTaskConfig]
    let tasksCountsMap: [String: (targetCount: Int, completedCount: Int)]
    let isFinished: Bool
    @Binding var creatingNewTask: Bool
    let disabled: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(taskConfigs) { taskConfig in
                    let (targetCount, completedCount) = tasksCountsMap[taskConfig.groupId]!
                    NavigationLink(value: taskConfig) {
                        TaskConfigInfoView(
                            config: taskConfig,
                            showingTaskType: true,
                            targetCount: targetCount,
                            completedCount: completedCount
                        )
                        .padding(10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(disabled)
                    .tint(.primary)
                    .foregroundStyle(.primary)
                }
                
                if taskConfigs.isEmpty {
                    if !isFinished && !disabled {
                        Button {
                            creatingNewTask = true
                        } label: {
                            Text("Создать задачу")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [themeModel.theme.accent1, themeModel.theme.accent2])
                                .padding(.horizontal)
                        }
                        .frame(height: UIScreen.height - 300)
                    } else {
                        Text("Нет задач")
                            .font(.title)
                            .foregroundStyle(.secondary)
                            .frame(height: UIScreen.height - 300)
                    }
                }
            }
            .padding(.bottom, disabled ? 30 : 120)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal)
    }
}
