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
    @Published var loading = false
    @Published var errorMessage: String?
    
    @Published var notificate = false
    @Published var lastTime = AppTime(hour: 8, minute: 0)
    @Published var lastInterval = 30
    @Published var comment = ""
    
    @Published var instance = AppTaskConfig(
        id: "",
        groupId: "",
        title: "",
        description: "",
        startingFrom: AppDate.fromDate(Date()),
        completedDate: nil,
        taskType: .goal,
        creationDate: AppDate.fromDate(Date()),
        imageValidation: false,
        onlyComment: true,
        time: nil,
        endTime: nil,
        isMomental: false,
        isHidden: false,
        maxProgress: 10,
        edgeProgress: 8,
        toFill: true,
        weekDays: []
    )
    
    var inited = false
    let center = UNUserNotificationCenter.current()
        
    var dismiss: () -> Void = {}
    let mainModel: MainViewModel
    let initialTaskConfig: AppTaskConfig?
    
    var hasChanges: Bool {
        guard let initialTaskConfig else { return false }
        return initialTaskConfig != instance
    }
    
    init(mainModel: MainViewModel, initialTaskConfig: AppTaskConfig?) {
        self.mainModel = mainModel
        self.initialTaskConfig = initialTaskConfig
    }
    
    var isEveryday: Bool {
        instance.weekDays.count == 7
    }
    
    func isTaskForDate(_ date: Date) -> Bool {
        guard let initialTaskConfig else { return false }
        return Calendar.current.differenceInDays(from: initialTaskConfig.startingFrom.dateValue(), to: date) >= 0 &&
        initialTaskConfig.weekDays.contains(WeekDay.getSelfFromValue(value: Calendar.current.component(.weekday, from: date)))
    }
    
    func initState(dismiss: @escaping () -> Void) {
        if !inited {
            self.dismiss = dismiss
            inited = true
            
            if let taskConfig = initialTaskConfig {
                instance = taskConfig
                updateNotifications()
            }
        }
    }
    
    func updateNotifications() {
        guard !instance.id.isEmpty else { return }
        center.getPendingNotificationRequests { [self] requests in
            Task { @MainActor in
                let count = requests.filter { $0.identifier.contains(instance.id) }.count
                
                if count == (isEveryday ? 1 : instance.weekDays.count) {
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
    
    func getPreparedConfig() -> AppTaskConfig {
        var instanceValue = instance
        
        if instance.taskType != .habit {
            instanceValue.weekDays = Set(WeekDay.allCases)
        }
        if instance.taskType == .goal {
            instanceValue.completedDate = instance.startingFrom
        }
        if instance.taskType == .tracker {
            instanceValue.time = nil
            instanceValue.endTime = nil
            instanceValue.onlyComment = true
        }
        
        return instanceValue
    }
    
    func createTaskConfig() {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                var instanceValue = getPreparedConfig()
                instanceValue.id = ""
                instanceValue.groupId = ""
                
                instance = try await FirebaseConstants.createTaskConfig(instance: instanceValue)
                
                mainModel.registerConfig(instance)
                
                if instance.time != nil && notificate {
                    setNotificate(true)
                }
                
                dismiss()
            } catch {
                errorMessage = "Не получилось создать задачу"
            }
        }
    }
    
    func updateTaskConfig() {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                let toNotificate = notificate
                setNotificate(false)
                
                var instanceValue = instance
                instanceValue.id = ""
                
                if instance.taskType != .goal {
                    let id = instance.id
                    
                    var completedDate = AppDate.fromDate(Calendar.current.date(byAdding: .day, value: -1, to: instance.startingFrom.dateValue())!)
                    
                    if mainModel.tasksMap[id]!.first(where: { Calendar.current.differenceInDays(from: instance.startingFrom.dateValue(), to: $0.completedDate.dateValue()) == 0 }) != nil {
                        completedDate = AppDate.fromDate(instance.startingFrom.dateValue())
                        instanceValue.startingFrom = AppDate.fromDate(Calendar.current.date(byAdding: .day, value: 1, to: instance.startingFrom.dateValue())!)
                    }
                    
                    try await FirebaseConstants.updateTaskConfig(id: id, completedDate: completedDate)
                    mainModel.registerConfigUpdate(id, completedDate: completedDate)
                    
                    instance = try await FirebaseConstants.createTaskConfig(instance: instanceValue)
                    mainModel.registerConfig(instance)
                } else {
                    try await FirebaseConstants.deleteTaskConfigGroup(configs: [instance])
                    mainModel.unregisterConfigGroup(id: instance.groupId)
                    instanceValue.groupId = ""
                    instanceValue.completedDate = instance.startingFrom
                    instance = try await FirebaseConstants.createTaskConfig(instance: instanceValue)
                    mainModel.registerConfig(instance)
                }
                    
                if instance.time != nil {
                    setNotificate(toNotificate)
                }
                
                dismiss()
            } catch {
                errorMessage = "Не получилось обновить задачу"
            }
        }
    }
    
    func toggleComplete(isTodayDeletion: Bool) {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                if instance.completedDate == nil {
                    var completedDate = AppDate.now()
                    if isTodayDeletion { completedDate = AppDate.fromDate(Calendar.current.date(byAdding: .day, value: -1, to: Date())!) }
                    try await FirebaseConstants.completeTask(id: instance.id, completedDate: completedDate)
                    mainModel.registerCompletion(of: instance.id, value: completedDate)
                    
                    let todayTask = isTodayDeletion ? mainModel.tasksMap[instance.id]!.first(where: { Calendar.current.isDateInToday($0.completedDate.dateValue()) }) : nil
                    if let todayTask {
                        try await FirebaseConstants.deleteTask(id: todayTask.id, configId: instance.id, imageUrls: todayTask.imageUrls)
                        mainModel.unregisterTask(id: todayTask.id, configId: instance.id)
                    }
                } else {
                    if Calendar.current.differenceInDays(from: instance.completedDate!.dateValue(), to: instance.startingFrom.dateValue()) == 0 {
                        try await FirebaseConstants.restoreTask(id: instance.id)
                        mainModel.registerCompletion(of: instance.id, value: nil)
                    } else {
                        try await FirebaseConstants.updateTaskConfig(id: instance.id, completedDate: instance.completedDate!)
                        mainModel.registerConfigUpdate(instance.id, completedDate: instance.completedDate!)
                        
                        var instanceValue = instance
                        instanceValue.id = ""
                        instanceValue.completedDate = nil
                        instance = try await FirebaseConstants.createTaskConfig(instance: instanceValue)
                        mainModel.registerConfig(instance)
                    }
                }
                
                setNotificate(false)
                
                dismiss()
            } catch {
                errorMessage = "Не получилось завершить задачу"
            }
        }
    }
    
    func deleteTaskConfig() {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                try await FirebaseConstants.deleteTaskConfigGroup(configs: mainModel.taskConfigs.filter { $0.groupId == instance.groupId })
                mainModel.unregisterConfigGroup(id: instance.groupId)
                instance.id = ""
                
                dismiss()
            } catch {
                errorMessage = "Не удалось удалить задачу"
            }
        }
    }
    
    func removeNotifications() {
        var identifiers: [String]
        if isEveryday { identifiers = [instance.id] }
        else { identifiers = instance.weekDays.map { instance.id + "\($0.value)" } }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func setNotificate(_ value: Bool) {
        guard instance.time != nil else { return }
        Task {
            do {
                if value {
                    let content = UNMutableNotificationContent()
                    content.title = "Предстоящая задача"
                    content.body = instance.title
                    
                    let identifiers: [String: Int] = isEveryday ? [instance.id: 1] : instance.weekDays.reduce([String: Int](), { partialResult, weekDay in
                        var partialResult = partialResult
                        partialResult["\(instance.id)\(weekDay.value)"] = weekDay.value
                        return partialResult
                    })
                    
                    for identifier in identifiers.keys {
                        var date = DateComponents()
                        date.hour = instance.time?.hour
                        date.minute = instance.time?.minute
                        if !isEveryday {
                            date.weekday = identifiers[identifier]
                        }
                        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                        
                        try await center.add(request)
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
