//
//  Tasks.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func createTaskConfig(instance: AppTaskConfig) async throws -> AppTaskConfig {
        guard let currentUserId else { throw AuthError.unexpected }
        
        let taskConfigDocRef = getTaskConfigDocRef(profileId: currentUserId)
        
        var instance = instance
        let id = instance.id.isEmpty ? taskConfigDocRef.documentID : instance.id
        let groupId = instance.groupId.isEmpty ? id : instance.groupId
        instance.id = id
        instance.groupId = groupId
        
        try await taskConfigDocRef.setData(try encode(instance))
        
        return instance
    }
    
    static func deleteTaskConfigGroup(configs: [AppTaskConfig]) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let batch = firestore.batch()
        
        for config in configs {
            let tasks = try await getTasks(configId: config.id)
            
            tasks.forEach { $0.imageUrls.forEach { url in deleteImage(url: url) } }
            tasks.forEach { batch.deleteDocument(getTaskDocRef(profileId: currentUserId, configId: config.id, id: $0.id)) }
            
            batch.deleteDocument(getTaskConfigDocRef(profileId: currentUserId, id: config.id))
        }
        
        try await batch.commit()
    }
    
    static func updateTaskConfig(id: String, completedDate: AppDate) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let doc = getTaskConfigDocRef(profileId: currentUserId, id: id)
        try await doc.updateData(try encode(UpdateTaskConfigParent(completedDate: completedDate)))
    }
    
    static func completeTask(id: String, completedDate: AppDate) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        try await getTaskConfigDocRef(profileId: currentUserId, id: id).updateData(try encode(CloseTaskUpdate(completedDate: completedDate)))
    }
    
    static func restoreTask(id: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        let data = ["completedDate": FieldValue.delete()]
        try await getTaskConfigDocRef(profileId: currentUserId, id: id).updateData(data)
    }
    
    static func createTask(configId: String, images: [UIImage], comment: String) async throws -> AppTask {
        guard let currentUserId else { throw AuthError.unexpected }
        let taskDocRef = getTaskDocRef(profileId: currentUserId, configId: configId)
        let imageUrls = try await images.asyncCompactMap { try await uploadImage(id: UUID().uuidString, image: $0) }
        
        let task = AppTask(
            id: taskDocRef.documentID,
            completedDate: AppDate.now(),
            imageUrls: imageUrls,
            comment: comment,
            progress: 1
        )
        try await taskDocRef.setData(try encode(task))
        
        return task
    }
    
    static func deleteTask(id: String, configId: String, imageUrls: [String]) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        imageUrls.forEach { deleteImage(url: $0) }
        try await getTaskDocRef(profileId: currentUserId, configId: configId, id: id).delete()
    }
    
    static func updateTaskProgress(id: String, configId: String, value: Int) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        try await getTaskDocRef(profileId: currentUserId, configId: configId, id: id).updateData(try encode(AppTaskProgressUpdate(progress: value)))
    }
    
    static func getTaskConfigs() async throws -> [AppTaskConfig] {
        guard let currentUserId else { throw AuthError.unexpected }
        let snapshot = try await getTaskConfigsCollectionRef(profileId: currentUserId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AppTaskConfig.self) }
    }
    
    static func getTasks(configId: String) async throws -> [AppTask] {
        guard let currentUserId else { throw AuthError.unexpected }
        let snapshot = try await getTasksCollectionRef(profileId: currentUserId, configId: configId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AppTask.self) }
    }
}
