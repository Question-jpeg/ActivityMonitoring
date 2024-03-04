//
//  ProfileViewModel.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

@MainActor
class MainViewModel: ObservableObject {
    let authModel: AuthViewModel
    
    @Published var taskConfigs = [AppTaskConfig]()
    @Published var tasksMap = [String: [AppTask]]()
    @Published var renderTasksMap = [String: [AppTask]]()
    
    @Published var usersMap = [String: User]()
    
    @Published var sharingUsers = [String]()
    @Published var gainingProfiles = [String]()
    
    @Published var sentSuggestionsMap = [String: Suggestion]()
    @Published var gainingSuggestionsMap = [String: Suggestion]()
    
    @Published var viewingTaskConfigs = [AppTaskConfig]()
    @Published var viewingTasksMap = [String: [AppTask]]()
    @Published var renderViewingTasksMap = [String: [AppTask]]()
    
    @Published var loadingId: String?
    @Published var errorMessage: String?
    @Published var loading = false
    
    var usersListener: ListenerRegistration?
    var profilesListener: ListenerRegistration?
    var sentSuggestionsListener: ListenerRegistration?
    var gainingSuggestionsListener: ListenerRegistration?
    var taskConfigsListener: ListenerRegistration?
    var taskListeners = [ListenerRegistration]()
    var lastProfileId: String?
    
    var sentSuggestions: [Suggestion] {
        Array(sentSuggestionsMap.values)
    }
    
    var gainingSuggestions: [Suggestion] {
        Array(gainingSuggestionsMap.values)
    }
    
    var usersWhoCanView: [User] {
        usersMap.values.filter { sharingUsers.contains($0.id) }
    }
    
    var availableProfiles: [User] {
        usersMap.values.filter { gainingProfiles.contains($0.id) }
    }
    
    var tasksCountsMap: [String: (targetCount: Int, completedCount: Int)] {
        var map = [String: (targetCount: Int, completedCount: Int)]()
        taskConfigs.forEach {
            if map[$0.groupId] == nil { map[$0.groupId] = (0, 0) }
            let data = $0.getTasksCountData(tasks: tasksMap[$0.id]!)
            map[$0.groupId]!.targetCount += data.targetCount
            map[$0.groupId]!.completedCount += data.completedCount
        }
        return map
    }
    
    var overallTasksCounts: (targetCount: Int, completedCount: Int) {
        tasksCountsMap.values.reduce((targetCount: 0, completedCount: 0)) { partialResult, current in
            (targetCount: partialResult.targetCount + current.targetCount, completedCount: partialResult.completedCount + current.completedCount)
        }
    }
    
    var viewingTasksCountsMap: [String: (targetCount: Int, completedCount: Int)] {
        var map = [String: (targetCount: Int, completedCount: Int)]()
        viewingTaskConfigs.forEach {
            if map[$0.groupId] == nil { map[$0.groupId] = (0, 0) }
            let data = $0.getTasksCountData(tasks: viewingTasksMap[$0.id]!)
            map[$0.groupId]!.targetCount += data.targetCount
            map[$0.groupId]!.completedCount += data.completedCount
        }
        return map
    }
    
    var viewingOverallTasksCounts: (targetCount: Int, completedCount: Int) {
        viewingTasksCountsMap.values.reduce((targetCount: 0, completedCount: 0)) { partialResult, current in
            (targetCount: partialResult.targetCount + current.targetCount, completedCount: partialResult.completedCount + current.completedCount)
        }
    }
    
    init(authModel: AuthViewModel) {
        self.authModel = authModel
        
        fetchData()
    }
    
    func unsubscribeAll() {
        usersListener?.remove()
        profilesListener?.remove()
        sentSuggestionsListener?.remove()
        gainingSuggestionsListener?.remove()
        taskConfigsListener?.remove()
        taskListeners.forEach { $0.remove() }
    }
    
    func fetchData() {
        loading = true
        Task {
            defer { loading = false }
            
            do {
                // users
                let users = try await FirebaseConstants.getUsers()
                mapUsers(users)
                
                usersListener = FirebaseConstants.usersCollection.addSnapshotListener { [self] snapshot, err in
                    let users = snapshot?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                    mapUsers(users)
                }
                
                // configs
                let configs = try await FirebaseConstants.getTaskConfigs()
                initTasksMap(configs)
                taskConfigs = configs
                            
                for taskConfig in configs {
                    Task {
                        let tasks = try await FirebaseConstants.getTasks(configId: taskConfig.id)
                        tasksMap[taskConfig.id] = tasks
                        renderTasksMap[taskConfig.id] = tasks.filter { Calendar.current.differenceInDays(from: $0.completedDate.dateValue(), to: Date()) <= 7 }
                    }
                }
                
                // sharings
                sharingUsers = try await FirebaseConstants.getGrantedUsers()
                profilesListener = try FirebaseConstants.getProfilesQuery().addSnapshotListener({ [self] snapshot, error in
                    gainingProfiles = snapshot?.documents.compactMap { (try? $0.data(as: GrantedUser.self))?.id } ?? []
                })
                
                // suggestions
                let suggestions = try await FirebaseConstants.getSendingSuggestions()
                mapSuggestions(suggestions)
                
                sentSuggestionsListener = try FirebaseConstants.getSendingSuggestionsQuery().addSnapshotListener({ [self] snapshot, error in
                    let suggestions = snapshot?.documents.compactMap { try? $0.data(as: Suggestion.self) } ?? []
                    mapSuggestionStatuses(suggestions)
                })
                gainingSuggestionsListener = try FirebaseConstants.getGainingSuggestionsQuery().addSnapshotListener({ [self] snapshot, error in
                    let suggestions = snapshot?.documents.compactMap { try? $0.data(as: Suggestion.self) } ?? []
                    mapGainingSuggestions(suggestions)
                })
            } catch {
                authModel.errorMessage = "Ошибка загрузки приложения"
            }
        }
    }
    
    func subscribeOn(profileId: String) {
        if lastProfileId == profileId { return }
        lastProfileId = profileId
        
        taskConfigsListener?.remove()
        
        taskConfigsListener = FirebaseConstants.getTaskConfigsQuery(profileId: profileId).addSnapshotListener({ [self] snapshot, error in
            let configs = snapshot?.documents.compactMap { (try? $0.data(as: AppTaskConfig.self)) } ?? []
            
            var map = [String: [AppTask]]()
            configs.forEach { map[$0.id] = [] }
            
            viewingTasksMap = map
            viewingTaskConfigs = configs
            
            taskListeners.forEach { $0.remove() }
            taskListeners = []
            
            configs.forEach { config in
                let listener = FirebaseConstants.getTasksQuery(profileId: profileId, configId: config.id).addSnapshotListener { [self] shot, err in
                    let tasks = shot?.documents.compactMap { try? $0.data(as: AppTask.self) } ?? []
                    viewingTasksMap[config.id] = tasks
                    renderViewingTasksMap[config.id] = tasks.filter { Calendar.current.differenceInDays(from: $0.completedDate.dateValue(), to: Date()) <= 7 }
                }
                taskListeners.append(listener)
            }
        })
    }
    
    func mapUsers(_ users: [User]) {
        users.forEach { usersMap[$0.id] = $0 }
    }
    
    func mapSuggestions(_ suggestions: [Suggestion]) {
        suggestions.forEach { sentSuggestionsMap[$0.id] = $0 }
    }
    
    func mapGainingSuggestions(_ suggestions: [Suggestion]) {
        var map = [String: Suggestion]()
        suggestions.forEach { map[$0.id] = $0 }
        gainingSuggestionsMap = map
    }
    
    func mapSuggestionStatuses(_ suggestions: [Suggestion]) {
        suggestions.forEach {
            sentSuggestionsMap[$0.id]?.status = $0.status
            sentSuggestionsMap[$0.id]?.comment = $0.comment
        }
    }
    
    func initTasksMap(_ configs: [AppTaskConfig]) {
        configs.forEach {
            tasksMap[$0.id] = []
            renderTasksMap[$0.id] = []
        }
    }
    
    func suggest(config: AppTaskConfig, toId: String) {
        loadingId = toId
        Task {
            defer { loadingId = nil }
            
            do {
                let suggestion = try await FirebaseConstants.createSuggestion(toUserId: toId, config: config)
                registerSuggestion(suggestion)
            } catch {
                errorMessage = "Не удалось назначить задачу"
            }
        }
    }
    
    func updateSuggestionStatus(_ status: SuggestionStatus, forSuggestion suggestion: Suggestion, comment: String) {
        loadingId = suggestion.id
        Task {
            defer { loadingId = nil }
            
            do {
                try await FirebaseConstants.updateSuggestionStatus(fromUserId: suggestion.fromId, id: suggestion.id, status: status, comment: comment)
            } catch {
                errorMessage = "Не удалось обновить статус предложения"
            }
        }
    }
    
    func removeSuggestion(_ suggestion: Suggestion) {
        loadingId = suggestion.id
        Task {
            defer { loadingId = nil }
            
            do {
                try await FirebaseConstants.removeSuggestion(toUserId: suggestion.toId, id: suggestion.id)
                unregisterSuggestion(suggestion.id)
            } catch {
                errorMessage = "Не удалось удалить предложение задачи"
            }
        }
    }
    
    func grantUser(id: String) {
        loadingId = id
        Task {
            defer { loadingId = nil }
            
            do {
                try await FirebaseConstants.grantUser(id: id)
                registerShare(id)
            } catch {
                errorMessage = "Не удалось поделиться с пользователем"
            }
        }
    }
    
    func revokeSharing(id: String) {
        loadingId = id
        Task {
            defer { loadingId = nil }
            
            do {
                try await FirebaseConstants.revokeSharing(id: id)
                unregisterShare(id)
            } catch {
                errorMessage = "Не удалось отозвать общий доступ"
            }
        }
    }
    
    func registerSuggestion(_ suggestion: Suggestion) {
        sentSuggestionsMap[suggestion.id] = suggestion
    }
    
    func unregisterSuggestion(_ id: String) {
        sentSuggestionsMap.removeValue(forKey: id)
    }
    
    func registerShare(_ id: String) {
        sharingUsers.append(id)
    }
    
    func unregisterShare(_ id: String) {
        sharingUsers.removeAll(where: { $0 == id })
    }
    
    func registerConfig(_ config: AppTaskConfig) {
        tasksMap[config.id] = []
        renderTasksMap[config.id] = []
        taskConfigs.append(config)
    }
    
    func registerConfigUpdate(_ id: String, completedDate: AppDate) {
        let index = taskConfigs.firstIndex(where: { $0.id == id })!
        taskConfigs[index].completedDate = completedDate
        taskConfigs[index].isHidden = true
    }
    
    func unregisterConfigGroup(id: String) {
        let toRemove = Set(taskConfigs.filter { $0.groupId == id })
        taskConfigs.removeAll(where: { toRemove.contains($0) })
        toRemove.forEach {
            tasksMap.removeValue(forKey: $0.id)
            renderTasksMap.removeValue(forKey: $0.id)
        }
    }
    
    func registerCompletion(of id: String, value: AppDate?) {
        taskConfigs[taskConfigs.firstIndex(where: { $0.id == id })!].completedDate = value
    }
    
    func registerTask(_ task: AppTask, configId: String) {
        tasksMap[configId]?.append(task)
        renderTasksMap[configId]?.append(task)
    }
    func unregisterTask(id: String, configId: String) {
        tasksMap[configId]?.removeAll(where: { $0.id == id })
        renderTasksMap[configId]?.removeAll(where: { $0.id == id })
    }
    
    func registerTaskProgress(id: String, configId: String, value: Int) {
        let index = tasksMap[configId]!.firstIndex(where: { $0.id == id })!
        let indexRender = renderTasksMap[configId]!.firstIndex(where: { $0.id == id })!
        
        tasksMap[configId]![index].progress = value
        renderTasksMap[configId]![indexRender].progress = value
    }
}
