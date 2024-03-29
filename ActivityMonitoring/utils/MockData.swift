//
//  MockData.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 07.02.2024.
//

import Firebase

struct MockData {
    static let user = User(id: UUID().uuidString, name: "Игорь Михайлов", imageUrl: "https://neweralive.na/storage/images/2023/may/lloyd-sikeba.jpg")
    static let users: [User] = [
        user,
        user,
        user
    ]
    
//    static let suggestions: [Suggestion] = [
//        .init(id: UUID().uuidString, fromId: <#T##String#>, toId: <#T##String#>, config: <#T##AppTaskConfig#>)
//    ]
    
    static let taskConfig = AppTaskConfig(
        id: UUID().uuidString,
        groupId: UUID().uuidString,
        title: "Stress Test Stress Test Stress Test Stress Test",
        description: "",
        startingFrom: AppDate.now(),
        taskType: .habit,
        creationDate: AppDate.now(),
        imageValidation: true,
        onlyComment: false,
        time: .init(hour: 8, minute: 0),
        endTime: .init(hour: 8, minute: 30),
        isMomental: true,
        isHidden: false,
        maxProgress: 0,
        edgeProgress: 0,
        toFill: true,
        weekDays: Set(WeekDay.allCases)
    )
    
    static let taskConfig2 = AppTaskConfig(
        id: UUID().uuidString,
        groupId: UUID().uuidString,
        title: "Test2",
        description: "some description",
        startingFrom: AppDate.now(),
        taskType: .habit,
        creationDate: AppDate.now(),
        imageValidation: true,
        onlyComment: false,
        time: nil,
        endTime: nil,
        isMomental: false,
        isHidden: false,
        maxProgress: 0,
        edgeProgress: 0,
        toFill: true,
        weekDays: Set(WeekDay.allCases)
    )
    
    static let taskConfig3 = AppTaskConfig(
        id: UUID().uuidString,
        groupId: UUID().uuidString,
        title: "Test3",
        description: "some description",
        startingFrom: AppDate.now(),
        taskType: .tracker,
        creationDate: AppDate.now(),
        imageValidation: false,
        onlyComment: false,
        time: .init(hour: 8, minute: 0),
        endTime: .init(hour: 8, minute: 30),
        isMomental: false,
        isHidden: false,
        maxProgress: 10,
        edgeProgress: 8,
        toFill: true,
        weekDays: Set(WeekDay.allCases)
    )
}
