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
    @State private var showingAssign = false
    @State private var comment = ""
    
    var suggestions: [Suggestion] {
        (suggestionId == nil && toAssign) ? mainModel.sentSuggestions.filter { $0.config.id == viewModel.createdId } : []
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
        !viewModel.title.isEmpty &&
        !viewModel.selectedWeekdays.isEmpty &&
        (!(viewModel.isTime && viewModel.isEndTime) || viewModel.endTime > viewModel.time)
    }
    
    var loading: Bool {
        viewModel.loading || mainModel.loadingId != nil
    }
    
    var disabled: Bool {
        viewModel.createdId != nil || viewModel.loading
    }
    
    var colorsForButton: [Color] {
        if loading || viewModel.completedDate != nil { return [Color(.systemGray), Color(.systemGray4)] }
        if toAssign { return [themeModel.theme.secAccent1, themeModel.theme.secAccent2] }
        if viewModel.createdId == nil { return [themeModel.theme.accent1, themeModel.theme.accent2] }
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
            
            Text(viewModel.createdId == nil ? "Создать задачу" :  (viewModel.completedDate == nil ? "Просмотр задачи" : "Завершённая задача"))
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
                viewModel.isTime.toggle()
            } label: {
                Text("Время")
                Image(systemName: viewModel.isTime ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(viewModel.isTime ? themeModel.theme.tint : .secondary)
            }
            Spacer()
            
            if viewModel.isTime {
                if viewModel.completedDate == nil && !toAssign {
                    Button {
                        viewModel.notificate.toggle()
                    } label: {
                        Image(systemName: viewModel.notificate ? "bell.fill" : "bell")
                            .font(.title2)
                            .foregroundStyle(viewModel.notificate ? themeModel.theme.tint : .secondary)
                    }
                    .disabled(viewModel.loading)
                }
                
                DatePicker("", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                    .frame(width: 90)
            }
        }
        .frame(maxWidth: .infinity)
        .appTextField()
        .tint(.primary)
        
        if viewModel.isTime {
            HStack {
                Button {
                    viewModel.endTime = Calendar.current.date(byAdding: .minute, value: 30, to: viewModel.time)!
                    viewModel.isEndTime.toggle()
                } label: {
                    Text("Время окончания")
                    Image(systemName: viewModel.isEndTime ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(viewModel.isEndTime ? themeModel.theme.tint : .secondary)
                }
                Spacer()
                
                if viewModel.isEndTime {
                    DatePicker("", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
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
            TextField("Название", text: $viewModel.title)
                .focused($focus, equals: .title)
                .submitLabel(.next)
                .onSubmit { focus = .description }
                .appTextField()
        }
        
        Button {
            focus = .description
        } label: {
            TextField("Описание", text: $viewModel.description)
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
                    config: viewModel.config,
                    showingTaskType: true
                )
                
                Spacer()
                
                if viewModel.completedDate == nil && viewModel.isTime && !toAssign {
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
                Text("Начиная с")
                Spacer()
                DatePicker("", selection: $viewModel.selectedStartingFrom, displayedComponents: .date)
                    .environment(\.locale, Locale.init(identifier: "ru_RU"))
            }
            .appTextField()
            
            VStack(spacing: 0) {
                Button {
                    if viewModel.isEveryday { viewModel.selectedWeekdays = [] }
                    else { viewModel.selectedWeekdays = WeekDay.allCases }
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
                        let isSelected = viewModel.selectedWeekdays.contains(weekday)
                        Button {
                            if isSelected { viewModel.selectedWeekdays.removeAll(where: { $0 == weekday }) }
                            else { viewModel.selectedWeekdays.append(weekday) }
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
        .disabled(disabled)
    }
    
    @ViewBuilder var typeAndImageOptions: some View {
        HStack {
            Text("Тип")
            Spacer()
            Picker("", selection: $viewModel.selectedTaskType) {
                ForEach(TaskType.allCases, id: \.self) { type in
                    HStack {
                        Text(type.title)
                        type.image
                    }
                }
            }
        }
        .appTextField()
        
        HStack {
            Button {
                viewModel.imageValidation.toggle()
            } label: {
                Text("Отчётность")
                Image(systemName: viewModel.imageValidation ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(viewModel.imageValidation ? themeModel.theme.tint : .secondary)
                Spacer()
            }
            
            if viewModel.imageValidation {
                Button {
                    viewModel.onlyComment.toggle()
                } label: {
                    Text("Фото")
                    Image(systemName: viewModel.onlyComment ? "square" : "checkmark.square.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.onlyComment ? .secondary : themeModel.theme.tint)
                }
            }
        }
        .appTextField()
        .tint(.primary)
    }
    
    @ViewBuilder var commentView: some View {
        if let suggestion {
            if !suggestion.isSending || !suggestion.comment.isEmpty {
                Button {
                    focus = .comment
                } label: {
                    VStack(alignment: .leading) {
                        if suggestion.isSending {
                            Text("Комментарий от получателя:")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        TextField("Добавить комментарий отправителю", text: suggestion.comment.isEmpty ? $comment : .constant(suggestion.comment))
                            .focused($focus, equals: .comment)
                            .appTextField()
                    }
                }
                .disabled(suggestion.isSending)
                .padding(.top)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                titleView
                if viewModel.createdId != nil {
                    configView
                }
                if viewModel.createdId == nil {
                    timeView
                    fieldsView
                }
                shortOptionsView
                if viewModel.createdId == nil {
                    typeAndImageOptions
                }
                commentView
                
                VStack {
                    if suggestion == nil || !suggestion!.isSending {
                        Button {
                            if isValid {
                                if let suggestion {
                                    viewModel.createTaskConfig(withId: suggestion.config.id)
                                    mainModel.updateSuggestionStatus(
                                        .accepted,
                                        forSuggestion: suggestion,
                                        comment: comment.isEmpty ? "Принято" : comment
                                    )
                                }
                                else if toAssign {
                                    if viewModel.createdId == nil {
                                        viewModel.createdId = UUID().uuidString
                                    }
                                    showingAssign = true
                                } else if viewModel.createdId == nil {
                                    viewModel.createTaskConfig()
                                } else {
                                    viewModel.toggleComplete()
                                }
                            } else {
                                viewModel.errorMessage = "Некорректное заполнение формы"
                            }
                        } label: {
                            Text(suggestion != nil ? "Принять" :
                                    (toAssign ? (suggestions.count > 0 ? "Назначено \(suggestions.count)" : "Назначить") :
                                        (viewModel.createdId == nil ? "Создать" :
                                            (viewModel.completedDate == nil ? "Завершить цикл задач" : "Восстановить"))))
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
                    
                    if viewModel.completedDate != nil || suggestion != nil {
                        Button {
                            if let suggestion {
                                if suggestion.isSending {
                                    mainModel.removeSuggestion(suggestion)
                                } else {
                                    mainModel.updateSuggestionStatus(
                                        .declined,
                                        forSuggestion: suggestion,
                                        comment: comment.isEmpty ? "Отклонено" : comment
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
        .sheet(isPresented: $showingAssign) {
            GrantedUsersView(assignConfig: viewModel.config)
                .padding(.top, 30)
                .background(themeModel.colorScheme == .dark ? .black : .white)
        }
    }
}

#Preview {
    TaskConfigDetailsView(
        mainModel: MainViewModel(authModel: AuthViewModel()),
        initialTaskConfig: nil,
        bottomPresenting: false,
        toAssign: true
    )
}
