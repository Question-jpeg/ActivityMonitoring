//
//  TaskCompletionViewModel.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 12.02.2024.
//

import SwiftUI
import Firebase

@MainActor
class TaskCompletionViewModel: ObservableObject {
    @Published var images = [UIImage]()
    @Published var comment = ""
    @Published var createdUrls = [String]()
    @Published var createdId: String?

    @Published var loadingIds = Set<String>()
    @Published var loading = false
    @Published var errorMessage: String?
    
    let mainModel: MainViewModel
    var dismiss: () -> Void = {}
    
    init(mainModel: MainViewModel) {
        self.mainModel = mainModel
    }
    
    func initState(task: AppTask?, showComment: Bool = true, dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
        images = []
        comment = showComment ? (task?.comment ?? "") : ""
        createdUrls = task?.imageUrls ?? []
        createdId = task?.id
    }
    
    func createTask(configId: String, isSheet: Bool) {
        guard !loadingIds.contains(configId) else { return }
        
        loadingIds.insert(configId)
        loading = true
        Task {
            defer { loadingIds.remove(configId); loading = false }
            
            let tempId = UUID().uuidString
            do {
                var appTask = AppTask(id: tempId, completedDate: AppDate.now(), imageUrls: [], comment: comment, progress: 1)
                mainModel.registerTask(appTask, configId: configId)
                
                appTask = try await FirebaseConstants.createTask(configId: configId, comment: comment)
                
                mainModel.unregisterTask(id: tempId, configId: configId)
                mainModel.registerTask(appTask, configId: configId)
                if isSheet { dismiss() }
                
                if !images.isEmpty {
                    let urls = try await FirebaseConstants.uploadTaskImages(configId: configId, id: appTask.id, images: images)
                    appTask.imageUrls = urls
                    mainModel.unregisterTask(id: appTask.id, configId: configId)
                    mainModel.registerTask(appTask, configId: configId)
                }
            } catch {
                mainModel.unregisterTask(id: tempId, configId: configId)
                errorMessage = "Не удалось выполнить задачу"
            }
        }
    }
    
    func deleteTask(id: String, configId: String, isSheet: Bool) {
        guard !loadingIds.contains(configId) else { return }
        
        loadingIds.insert(configId)
        loading = true
        Task {
            defer { loadingIds.remove(configId); loading = false }
            let removedTask = mainModel.tasksMap[configId]!.first(where: { $0.id == id })!
            do {
                mainModel.unregisterTask(id: id, configId: configId)
                try await FirebaseConstants.deleteTask(id: id, configId: configId, imageUrls: isSheet ? createdUrls : [])
                if isSheet { dismiss() }
            } catch {
                mainModel.registerTask(removedTask, configId: configId)
                errorMessage = "Не удалось возобновить задачу"
            }
        }
    }
    
    func setTaskProgress(id: String, configId: String, from: Int, value: Int, fromComment: String = "", comment: String = "", isSheet: Bool) {
        guard !loadingIds.contains(configId) else { return }
        
        loadingIds.insert(configId)
        loading = true
        Task {
            defer { loadingIds.remove(configId); loading = false }
            
            do {
                mainModel.registerTaskProgress(id: id, configId: configId, value: value, comment: comment)
                try await FirebaseConstants.updateTaskProgress(id: id, configId: configId, value: value, comment: comment)
                if isSheet { dismiss() }
            } catch {
                mainModel.registerTaskProgress(id: id, configId: configId, value: from, comment: fromComment)
                errorMessage = "Не удалось обновить прогресс трекера"
            }
        }
    }
}
