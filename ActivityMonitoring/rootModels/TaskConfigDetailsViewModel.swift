//
//  TaskConfigDetailsViewModel.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 12.02.2024.
//

import Firebase
import SwiftUI

@MainActor
class TaskConfigDetailsViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var selectedWeekdays = [WeekDay]()
    @Published var selectedStartingFrom = Date()
    @Published var selectedTaskType = TaskType.habit
    @Published var imageValidation = false
    @Published var onlyComment = true
    @Published var time = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @Published var endTime = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!
    @Published var isTime = false
    @Published var isEndTime = false
    @Published var notificate = false
    @Published var createdId: String?
    @Published var completedDate: Date?
    
    @Published var loading = false
    @Published var errorMessage: String?
    
    var inited = false
    let center = UNUserNotificationCenter.current()
        
    var dismiss: () -> Void = {}
    let mainModel: MainViewModel
    let initialTaskConfig: AppTaskConfig?
    
    init(mainModel: MainViewModel, initialTaskConfig: AppTaskConfig?) {
        self.mainModel = mainModel
        self.initialTaskConfig = initialTaskConfig
    }
    
    var isEveryday: Bool {
        selectedWeekdays.count == 7
    }
    
    var config: AppTaskConfig {
        return .init(
            id: createdId ?? UUID().uuidString,
            title: title,
            description: description,
            startingFrom: AppDate.fromDate(selectedStartingFrom),
            taskType: selectedTaskType,
            creationDate: AppDate.now(),
            imageValidation: imageValidation,
            onlyComment: onlyComment,
            time: isTime ? AppTime.fromDate(time) : nil,
            endTime: isEndTime ? AppTime.fromDate(endTime) : nil,
            weekDays: selectedWeekdays
        )
    }
    
    func initState(initialConfig: AppTaskConfig? = nil, dismiss: @escaping () -> Void) {
        if !inited {
            self.dismiss = dismiss
            inited = true
            
            if let taskConfig = initialConfig ?? initialTaskConfig {
                title = taskConfig.title
                description = taskConfig.description
                selectedStartingFrom = taskConfig.startingFrom.dateValue()
                selectedWeekdays = taskConfig.weekDays
                selectedTaskType = taskConfig.taskType
                imageValidation = taskConfig.imageValidation
                onlyComment = taskConfig.onlyCommentBool
                completedDate = taskConfig.completedDate?.dateValue()
                if let appTime = taskConfig.time {
                    time = Calendar.current.date(bySettingHour: appTime.hour, minute: appTime.minute, second: 0, of: Date())!
                    isTime = true
                    
                    if let appEndTime = taskConfig.endTime {
                        endTime = Calendar.current.date(bySettingHour: appEndTime.hour, minute: appEndTime.minute, second: 0, of: Date())!
                        isEndTime = true
                    }
                }
                
                createdId = taskConfig.id
                updateNotifications()
            }
        }
    }
    
    func updateNotifications() {
        guard let id = createdId else { return }
        center.getPendingNotificationRequests { [self] requests in
            Task { @MainActor in
                let count = requests.filter { $0.identifier.contains(id) }.count
                
                if count == (selectedWeekdays.count == 7 ? 1 : selectedWeekdays.count) {
                    notificate = true
                } else {
                    if count != 0 {
                        removeNotifications()
                        updateNotifications()
                    } else {
                        notificate = false
                    }
                }
            }
        }
    }
    
    func createTaskConfig(withId id: String? = nil) {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                var appTime: AppTime? = nil
                var endAppTime: AppTime? = nil
                if isTime {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                    appTime = AppTime(hour: components.hour!, minute: components.minute!)
                    
                    if isEndTime {
                        let componentsEnd = Calendar.current.dateComponents([.hour, .minute], from: endTime)
                        endAppTime = AppTime(hour: componentsEnd.hour!, minute: componentsEnd.minute!)
                    }
                }
                
                let config = try await FirebaseConstants.createTaskConfig(
                    withId: id,
                    title: title,
                    description: description,
                    weekDays: selectedWeekdays,
                    startingFrom: selectedStartingFrom,
                    taskType: selectedTaskType,
                    imageValidation: imageValidation,
                    onlyComment: onlyComment,
                    time: appTime,
                    endTime: endAppTime
                )
                
                mainModel.registerConfig(config)
                createdId = config.id
                
                if isTime && notificate {
                    setNotificate(true)
                }
                
                dismiss()
            } catch {
                errorMessage = "Не получилось создать задачу"
            }
        }
    }
    
    func toggleComplete() {
        guard let id = createdId else { return }
        loading = true
        Task {
            defer { loading = false }
            
            do {
                var value: Date? = nil
                if completedDate == nil {
                    try await FirebaseConstants.completeTask(id: id)
                    value = Date()
                } else {
                    try await FirebaseConstants.restoreTask(id: id)
                }
                                 
                mainModel.registerCompletion(of: id, value: value == nil ? nil : AppDate.fromDate(value!))
                completedDate = value
                
                setNotificate(false)
            } catch {
                errorMessage = "Не получилось завершить задачу"
            }
        }
    }
    
    func deleteTaskConfig() {
        guard let id = createdId else { return }
        loading = true
        Task {
            defer { loading = false }
            
            do {
                let tasks = mainModel.tasksMap[id]!
                try await FirebaseConstants.deleteTaskConfig(id: id, withTasks: tasks)
                
                mainModel.unregisterConfig(id: id)
                createdId = nil
                
                dismiss()
            } catch {
                errorMessage = "Не удалось удалить задачу"
            }
        }
    }
    
    func removeNotifications() {
        guard let id = createdId else { return }
                
        var identifiers: [String]
        if isEveryday { identifiers = [id] }
        else { identifiers = selectedWeekdays.map { id + "\($0.value)" } }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func setNotificate(_ value: Bool) {
        guard let id = createdId else { return }
        Task {
            do {
                if value {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                    let content = UNMutableNotificationContent()
                    content.title = "Предстоящая задача"
                    content.body = title
                                        
                    for weekday in selectedWeekdays {
                        var date = DateComponents()
                        date.hour = components.hour
                        date.minute = components.minute
                        if !isEveryday {
                            date.weekday = weekday.value
                        }
                        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                        let request = UNNotificationRequest(identifier: id + (isEveryday ? "" : "\(weekday.value)"), content: content, trigger: trigger)
                        
                        try await center.add(request)
                        if isEveryday { break }
                    }
                    
                    updateNotifications()
                } else {
                    removeNotifications()
                    updateNotifications()
                }
            } catch {
                errorMessage = "Не получилось назначить уведомления"
                removeNotifications()
                updateNotifications()
            }
        }
    }
}
