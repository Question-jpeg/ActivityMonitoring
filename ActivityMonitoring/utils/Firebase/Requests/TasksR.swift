//
//  Tasks.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import Firebase

extension FirebaseConstants {
    static func createTaskConfig(
        withId id: String? = nil,
        title: String,
        description: String,
        weekDays: [WeekDay],
        startingFrom: Date,
        taskType: TaskType,
        imageValidation: Bool,
        time: AppTime?,
        endTime: AppTime?
        ) async throws -> AppTaskConfig {
        guard let currentUserId else { throw AuthError.unexpected }
        let taskConfigDocRef = getTaskConfigDocRef(profileId: currentUserId, id: id)
        let data = AppTaskConfig(
            id: taskConfigDocRef.documentID,
            title: title,
            description: description,
            startingFrom: AppDate.fromDate(startingFrom),
            taskType: taskType,
            creationDate: AppDate.now(),
            imageValidation: imageValidation,
            time: time,
            endTime: endTime,
            weekDays: weekDays
        )
        try await taskConfigDocRef.setData(try encode(data))
        
        return data
    }
    
    static func deleteTaskConfig(id: String, withTasks tasks: [AppTask]) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        
        tasks.forEach { $0.imageUrls.forEach { url in deleteImage(url: url) } }
        
        let batch = firestore.batch()
        tasks.map { getTaskDocRef(profileId: currentUserId, configId: id, id: $0.id) }.forEach { batch.deleteDocument($0) }
        
        batch.deleteDocument(getTaskConfigDocRef(profileId: currentUserId, id: id))
        
        try await batch.commit()
    }
    
    static func setNotifications(value: Bool, forTaskConfigId id: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        try await getTaskConfigDocRef(profileId: currentUserId, id: id).updateData(try encode(UpdateNotificate(notificate: value)))
    }
    
    static func completeTask(id: String) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        try await getTaskConfigDocRef(profileId: currentUserId, id: id).updateData(try encode(CloseTaskUpdate(completedDate: AppDate.now())))
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
            comment: comment
        )
        try await taskDocRef.setData(try encode(task))
        
        return task
    }
    
    static func deleteTask(id: String, configId: String, imageUrls: [String]) async throws {
        guard let currentUserId else { throw AuthError.unexpected }
        imageUrls.forEach { deleteImage(url: $0) }
        try await getTaskDocRef(profileId: currentUserId, configId: configId, id: id).delete()
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
