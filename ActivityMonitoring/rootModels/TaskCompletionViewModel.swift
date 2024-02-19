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
    
    var loadingIds = [String]()
    @Published var loading = false
    @Published var errorMessage: String?
    
    let mainModel: MainViewModel
    var dismiss: () -> Void = {}
    
    init(mainModel: MainViewModel) {
        self.mainModel = mainModel
    }
    
    func initState(task: AppTask?, dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
        images = []
        comment = task?.comment ?? ""
        createdUrls = task?.imageUrls ?? []
        createdId = task?.id
    }
    
    func createTask(configId: String, isSheet: Bool) {
        guard !loadingIds.contains(configId) else { return }
        
        loadingIds.append(configId)
        loading = true
        Task {
            defer { loadingIds.removeAll(where: { $0 == configId }); loading = false }
            
            let tempId = UUID().uuidString
            do {
                var appTask = AppTask(id: tempId, completedDate: AppDate.now(), imageUrls: [], comment: comment)
                mainModel.registerTask(appTask, configId: configId)
                
                appTask = try await FirebaseConstants.createTask(configId: configId, images: images, comment: comment)
                
                mainModel.unregisterTask(id: tempId, configId: configId)
                mainModel.registerTask(appTask, configId: configId)
                if isSheet { dismiss() }
            } catch {
                mainModel.unregisterTask(id: tempId, configId: configId)
                errorMessage = "Не удалось выполнить задачу"
            }
        }
    }
    
    func deleteTask(id: String, configId: String, isSheet: Bool) {
        guard !loadingIds.contains(configId) else { return }
        
        loadingIds.append(configId)
        loading = true
        Task {
            defer { loadingIds.removeAll(where: { $0 == configId }); loading = false }
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
}
