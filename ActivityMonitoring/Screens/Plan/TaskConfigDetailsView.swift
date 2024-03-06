//
//  CreateTaskConfigView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import SwiftUI

enum TaskConfigField {
    case title, description, comment
}

struct TaskConfigDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    @StateObject var viewModel: TaskConfigDetailsViewModel
    
    let bottomPresenting: Bool
    let toAssign: Bool
    let suggestionId: String?
    
    @FocusState private var focus: TaskConfigField?
    @State private var showingDeleteAlert = false
    @State private var showingCompleteAlert = false
    @State private var showingAssign = false
    
    var suggestions: [Suggestion] {
        (suggestionId == nil && toAssign) ? mainModel.sentSuggestions.filter { $0.config.id == viewModel.instance.id } : []
    }
    
    var suggestion: Suggestion? {
        suggestionId != nil ? (toAssign ?
                               mainModel.sentSuggestionsMap[suggestionId!] :
                                mainModel.gainingSuggestionsMap[suggestionId!]) : nil
    }
    
    init(mainModel: MainViewModel, initialTaskConfig: AppTaskConfig? = nil, bottomPresenting: Bool = false, toAssign: Bool = false, suggestionId: String? = nil) {
        self.bottomPresenting = bottomPresenting
        self.toAssign = toAssign
        self.suggestionId = suggestionId
        
        _viewModel = StateObject(wrappedValue: TaskConfigDetailsViewModel(
            mainModel: mainModel,
            initialTaskConfig: initialTaskConfig
        ))
    }
    
    var isValid: Bool {
        !viewModel.instance.title.isEmpty &&
        (viewModel.instance.taskType != .habit || !viewModel.instance.weekDays.isEmpty) &&
        ((viewModel.instance.time == nil || viewModel.instance.endTime == nil) || viewModel.instance.endTime! > viewModel.instance.time!) &&
        Calendar.current.differenceInDays(from: Date(), to: viewModel.instance.startingFrom.dateValue()) >= 0
    }
    
    var loading: Bool {
        viewModel.loading || mainModel.loadingId != nil
    }
    
    var colorsForButton: [Color] {
        if loading || viewModel.instance.isCompleted { return [Color(.systemGray), Color(.systemGray4)] }
        if toAssign { return [themeModel.theme.secAccent1, themeModel.theme.secAccent2] }
        if viewModel.instance.id.isEmpty { return [themeModel.theme.accent1, themeModel.theme.accent2] }
        return [themeModel.theme.complete1, themeModel.theme.complete2]
    }
    
    @ViewBuilder var titleView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: bottomPresenting ? "arrow.down" : "arrow.left")
                    .foregroundStyle(themeModel.theme.tint)
                    .font(.title)
            }
            
            Spacer()
            
            Text(viewModel.instance.id.isEmpty ? "Создать задачу" :  (viewModel.instance.isCompleted ? "Завершённая задача" : "Просмотр задачи"))
                .font(.title)
            
            Spacer()
            
            Image(systemName: "arrow.left")
                .font(.title)
                .opacity(0)
        }
    }
    
    @ViewBuilder var timeView: some View {
        HStack {
            Button {
                if viewModel.instance.time == nil {
                    viewModel.instance.time = viewModel.lastTime
                } else {
                    viewModel.lastTime = viewModel.instance.time!
                    viewModel.instance.time = nil
                    viewModel.instance.endTime = nil
                    viewModel.instance.isMomental = false
                }
            } label: {
                Text("Время")
                Image(systemName: viewModel.instance.time != nil ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(viewModel.instance.time != nil ? themeModel.theme.tint : .secondary)
            }
            Spacer()
            
            if viewModel.instance.time != nil {
                if viewModel.instance.id.isEmpty && !toAssign {
                    Button {
                        viewModel.notificate.toggle()
                    } label: {
                        Image(systemName: viewModel.notificate ? "bell.fill" : "bell")
                            .font(.title2)
                            .foregroundStyle(viewModel.notificate ? themeModel.theme.tint : .secondary)
                    }
                    .disabled(viewModel.loading)
                }
                
                DatePicker("", selection: Binding(
                        get: { viewModel.instance.time!.dateValue() },
                        set: {
                            viewModel.instance.time = AppTime.fromDate($0)
                            if viewModel.instance.endTime != nil {
                                viewModel.instance.endTime = viewModel.instance.time?.add(viewModel.lastInterval)
                            }
                        }),
                    displayedComponents: .hourAndMinute
                )
                    .frame(width: 90)
            }
        }
        .frame(maxWidth: .infinity)
        .appTextField()
        .tint(.primary)
        
        if viewModel.instance.time != nil {
            HStack {
                Button {
                    if viewModel.instance.endTime == nil {
                        viewModel.instance.endTime = viewModel.instance.time!.add(viewModel.lastInterval)
                    } else {
                        viewModel.instance.endTime = nil
                        viewModel.instance.isMomental = false
                    }
                } label: {
                    Text("Время окончания")
                    Image(systemName: viewModel.instance.endTime != nil ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(viewModel.instance.endTime != nil ? themeModel.theme.tint : .secondary)
                }
                Spacer()
                
                if let endTime = viewModel.instance.endTime {
                    Button {
                        viewModel.instance.isMomental.toggle()
                    } label: {
                        Image(systemName: viewModel.instance.isMomental ? "bolt.fill" : "bolt")
                            .font(.title2)
                            .foregroundStyle(viewModel.instance.isMomental ? themeModel.theme.tint : .secondary)
                    }
                    DatePicker("", selection: Binding(
                            get: { endTime.dateValue() },
                            set: { 
                                viewModel.instance.endTime = AppTime.fromDate($0)
                                viewModel.lastInterval = viewModel.instance.time!.getDistanceTo(viewModel.instance.endTime!)
                            }),
                        displayedComponents: .hourAndMinute
                    )
                        .frame(width: 90)
                }
            }
            .frame(maxWidth: .infinity)
            .appTextField()
            .tint(.primary)
        }
    }
    
    @ViewBuilder var fieldsView: some View {
        Button {
            focus = .title
        } label: {
            TextField("Название", text: $viewModel.instance.title)
                .focused($focus, equals: .title)
                .submitLabel(.next)
                .onSubmit { focus = .description }
                .appTextField()
        }
        
        Button {
            focus = .description
        } label: {
            TextField("Описание", text: $viewModel.instance.description)
                .focused($focus, equals: .description)
                .submitLabel(.continue)
                .appTextField()
        }
    }
    
    @ViewBuilder var configView: some View {
        if let suggestion {
            SuggestionCell(suggestion: suggestion, isShowingBell: !toAssign, bellState: viewModel.notificate) {
                viewModel.notificate.toggle()
            }
        } else {
            HStack {
                TaskConfigInfoView(
                    config: viewModel.instance,
                    showingTaskType: true
                )
                
                Spacer()
                
                if !viewModel.instance.isCompleted && viewModel.instance.time != nil && !toAssign {
                    Button {
                        viewModel.setNotificate(!viewModel.notificate)
                    } label: {
                        Image(systemName: viewModel.notificate ? "bell.fill" : "bell")
                            .font(.title2)
                            .foregroundStyle(viewModel.notificate ? themeModel.theme.tint : .secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    @ViewBuilder var shortOptionsView: some View {
        VStack {
            HStack {
                Text(viewModel.instance.taskType != .goal ? "Начиная с" : "Назначая на")
                Spacer()
                DatePicker("", selection: Binding(
                    get: { viewModel.instance.startingFrom.dateValue() },
                    set: { viewModel.instance.startingFrom = AppDate.fromDate($0) }),
                    in: Date()...,
                    displayedComponents: .date
                )
                .environment(\.locale, Locale.init(identifier: "ru_RU"))
            }
            .appTextField()
            
            if viewModel.instance.taskType == .habit {
                VStack(spacing: 0) {
                    Button {
                        if viewModel.isEveryday { viewModel.instance.weekDays = [] }
                        else { viewModel.instance.weekDays = Set(WeekDay.allCases) }
                    } label: {
                        HStack {
                            Text("Ежедневно")
                            Image(systemName: viewModel.isEveryday ? "checkmark.square.fill" : "square")
                                .foregroundStyle(viewModel.isEveryday ? themeModel.theme.tint : .secondary)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                    
                    HStack {
                        ForEach(WeekDay.allCases, id: \.self) { weekday in
                            let isSelected = viewModel.instance.weekDays.contains(weekday)
                            Button {
                                if isSelected { viewModel.instance.weekDays.remove(weekday) }
                                else { viewModel.instance.weekDays.insert(weekday) }
                            } label: {
                                Text(weekday.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .padding(10)
                                    .background(isSelected ? themeModel.theme.tint : Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, -10)
                .appTextField()
            }
        }
    }
    
    @ViewBuilder var typeOption: some View {
        HStack {
            Text("Тип")
            Spacer()
            Picker("", selection: $viewModel.instance.taskType) {
                ForEach(TaskType.allCases, id: \.self) { type in
                    HStack {
                        Text(type.title)
                        type.image
                    }
                }
            }
        }
        .appTextField()
    }
    
    @ViewBuilder var imageOption: some View {
        HStack {
            Button {
                viewModel.instance.imageValidation.toggle()
            } label: {
                Text("Отчётность")
                Image(systemName: viewModel.instance.imageValidation ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(viewModel.instance.imageValidation ? themeModel.theme.tint : .secondary)
                Spacer()
            }
            
            if viewModel.instance.imageValidation {
                Button {
                    if viewModel.instance.onlyComment { viewModel.instance.onlyComment = false }
                    else { viewModel.instance.onlyComment = true }
                } label: {
                    Text("Фото")
                    Image(systemName: viewModel.instance.onlyComment ? "square" : "checkmark.square.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.instance.onlyComment ? .secondary : themeModel.theme.tint)
                }
            }
        }
        .appTextField()
        .tint(.primary)
    }
    
    @ViewBuilder var commentView: some View {
        Button {
            focus = .comment
        } label: {
            VStack(alignment: .leading) {
                if suggestion!.isSending {
                    Text("Комментарий от получателя:")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                TextField("Добавить комментарий отправителю", text: suggestion!.comment.isEmpty ? $viewModel.comment : .constant(suggestion!.comment))
                    .focused($focus, equals: .comment)
                    .appTextField()
            }
        }
        .disabled(suggestion!.isSending)
        .padding(.top)
    }
    
    @ViewBuilder var trackerView: some View {
        VStack {
            Text("Количество делений: \(viewModel.instance.maxProgress.formatted())")
                .foregroundStyle(.secondary)
            Slider(value: Binding(get: {
                Double(viewModel.instance.maxProgress)
            }, set: {
                let value = Int($0)
                viewModel.instance.maxProgress = value
                if value < viewModel.instance.edgeProgress { viewModel.instance.edgeProgress = value }
            }), in: 3...10)
        }
        .appTextField()
        
        VStack {
            Text("Граница выполнения: \(viewModel.instance.edgeProgress.formatted())")
                .foregroundStyle(.secondary)
            Slider(value: Binding(get: {
                Double(viewModel.instance.edgeProgress)
            }, set: {
                viewModel.instance.edgeProgress = Int($0)
            }), in: 2...Double(viewModel.instance.maxProgress))
        }
        .appTextField()
        
        Picker("", selection: $viewModel.instance.toFill) {
            Text("Больше - хуже")
                .tag(false)
            Text("Больше - лучше")
                .tag(true)
        }
        .pickerStyle(.segmented)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                titleView
                if !viewModel.instance.id.isEmpty {
                    configView
                }
                
                if viewModel.instance.id.isEmpty {
                    typeOption
                }
                
                if suggestion == nil && !viewModel.instance.isCompleted {
                    if viewModel.instance.taskType != .tracker {
                        timeView
                    }
                    fieldsView
                    
                    if viewModel.instance.taskType == .tracker {
                        trackerView
                    }
                }
                                
                shortOptionsView
                    .disabled(suggestion != nil)
                
                if viewModel.instance.taskType != .tracker {
                    imageOption
                }
                if let suggestion {
                    if !suggestion.isSending || !suggestion.comment.isEmpty {
                        commentView
                    }
                }
                
                VStack {
                    if suggestion == nil && !viewModel.instance.isCompleted && viewModel.hasChanges {
                        Button {
                            if isValid {
                                viewModel.updateTaskConfig()
                            } else {
                                viewModel.errorMessage = "Некорректное заполнение формы"
                            }
                        } label: {
                            Text("Обновить")
                                .frame(maxWidth: .infinity)
                                .overlay {
                                    if loading {
                                        HStack {
                                            ProgressView()
                                            Spacer()
                                            ProgressView()
                                        }
                                        .tint(.white)
                                    }
                                }
                                .appCardStyle(colors: loading ?
                                              [Color(.systemGray), Color(.systemGray4)] :
                                                [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
                        }
                    }
                    if (viewModel.instance.taskType != .goal || viewModel.instance.id.isEmpty) && (suggestion == nil || !suggestion!.isSending) {
                        Button {
                            if suggestion == nil && !toAssign && !viewModel.instance.id.isEmpty {
                                if viewModel.instance.isCompleted || !viewModel.isTaskForDate(Date()) {
                                    viewModel.toggleComplete(isTodayDeletion: false)
                                } else {
                                    showingCompleteAlert = true
                                }
                            } else if isValid {
                                if let suggestion {
                                    viewModel.createTaskConfig()
                                    mainModel.updateSuggestionStatus(
                                        .accepted,
                                        forSuggestion: suggestion,
                                        comment: viewModel.comment.isEmpty ? "Принято" : viewModel.comment
                                    )
                                }
                                else if toAssign {
                                    if viewModel.instance.id.isEmpty {
                                        viewModel.instance.id = UUID().uuidString
                                    }
                                    showingAssign = true
                                } else if viewModel.instance.id.isEmpty {
                                    viewModel.createTaskConfig()
                                }
                            } else {
                                viewModel.errorMessage = "Некорректное заполнение формы"
                            }
                        } label: {
                            Text(suggestion != nil ? "Принять" :
                                    (toAssign ? (suggestions.count > 0 ? "Назначено \(suggestions.count)" : "Назначить") :
                                        (viewModel.instance.id.isEmpty ? "Создать" :
                                            (viewModel.instance.isCompleted ? "Восстановить" : "Завершить цикл задач"))))
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if loading {
                                    HStack {
                                        ProgressView()
                                        Spacer()
                                        ProgressView()
                                    }
                                    .tint(.white)
                                }
                            }
                            .appCardStyle(colors: colorsForButton)
                        }
                        .disabled(loading)
                    }
                    
                    if (viewModel.instance.taskType == .goal ? !viewModel.instance.id.isEmpty : viewModel.instance.isCompleted) || suggestion != nil {
                        Button {
                            if let suggestion {
                                if suggestion.isSending {
                                    mainModel.removeSuggestion(suggestion)
                                } else {
                                    mainModel.updateSuggestionStatus(
                                        .declined,
                                        forSuggestion: suggestion,
                                        comment: viewModel.comment.isEmpty ? "Отклонено" : viewModel.comment
                                    )
                                }
                            } else {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Text(suggestion == nil ? "Удалить" :
                                    (suggestion!.isSending ? (suggestion?.status == .pending ? "Отозвать" : "Очистить") :
                                        "Отклонить"))
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if (loading) {
                                    HStack {
                                        ProgressView()
                                        Spacer()
                                        ProgressView()
                                    }
                                    .tint(.white)
                                }
                            }
                            .appCardStyle(colors: loading ?
                                          [Color(.systemGray), Color(.systemGray4)] :
                                            [themeModel.theme.delete1, themeModel.theme.delete2]
                            )
                        }
                        .disabled(loading)
                    }
                }
                .padding(.top, 20)
            }
            .padding()
            .padding(.vertical)
            .tint(themeModel.theme.tint)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            viewModel.initState(dismiss: { dismiss() })
        }
        .onChange(of: suggestion == nil, { _, _ in
            if suggestionId != nil && suggestion == nil { dismiss() }
        })
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(title: Text(errorMessage))
        }
        .alert("Удаление задачи повлечёт за собой удаление истории по этой задаче. Продолжить?", isPresented: $showingDeleteAlert) {
            Text("Отмена")
            Button {
                viewModel.deleteTaskConfig()
            } label: {
                Text("Удалить")
            }
        }
        .alert("Завершение цикла задач. Исключить из списка эту задачу на сегодня?", isPresented: $showingCompleteAlert) {
            Button {
                viewModel.toggleComplete(isTodayDeletion: true)
            } label: {
                Text("Исключить")
            }
            Button {
                viewModel.toggleComplete(isTodayDeletion: false)
            } label: {
                Text("Оставить")
            }
            Text("Отмена")
        }
        .sheet(isPresented: $showingAssign) {
            GrantedUsersView(assignConfig: viewModel.instance)
        }
    }
}

#Preview {
    let mainModel = MainViewModel(authModel: AuthViewModel())
    return TaskConfigDetailsView(
        mainModel: mainModel,
        initialTaskConfig: nil,
        bottomPresenting: true,
        toAssign: false
    )
    .environmentObject(mainModel)
    .environmentObject(AppThemeModel())
}
