//
//  Task.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 07.02.2024.
//

import SwiftUI

enum TaskType: Int, CaseIterable, Codable {
    case habit, goal
    
    var title: String {
        switch self {
        case .habit:
            return "Привычка"
        case .goal:
            return "Цель"
        }
    }
    
    var image: Image {
        switch self {
        case .habit:
            return Image(systemName: "arrow.triangle.2.circlepath")
        case .goal:
            return Image(systemName: "scope")
        }
    }
}

enum WeekDay: Int, CaseIterable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    var title: String {
        switch self {
        case .monday:
            return "Пн"
        case .tuesday:
            return "Вт"
        case .wednesday:
            return "Ср"
        case .thursday:
            return "Чт"
        case .friday:
            return "Пт"
        case .saturday:
            return "Сб"
        case .sunday:
            return "Вс"
        }
    }
    
    var value: Int {
        switch self {
        case .monday:
            return 2
        case .tuesday:
            return 3
        case .wednesday:
            return 4
        case .thursday:
            return 5
        case .friday:
            return 6
        case .saturday:
            return 7
        case .sunday:
            return 1
        }
    }
    
    static func getWeekDaysInterval(fromWeekDay: Int, toWeekDay: Int) -> [Int] {
        var result = [Int]()
        if fromWeekDay > toWeekDay {
            (fromWeekDay...7).forEach { result.append($0) }
            (1..<toWeekDay).forEach { result.append($0) }
        } else {
            (fromWeekDay..<toWeekDay).forEach { result.append($0) }
        }
        
        return result
    }
    
    static func getWeekDayByAdding(value: Int, to: Int) -> Int {
        return (value + to - 1) % 7 + 1
    }
    
    static func getSelfFromValue(value: Int) -> Self {
        WeekDay.allCases.first(where: { $0.value == value })!
    }
}

struct CloseTaskUpdate: Codable {
    let completedDate: AppDate
}

struct UpdateNotificate: Codable {
    let notificate: Bool
}

struct AppTaskConfigUpdate: Codable {
    let title: String
    let description: String
    let taskType: TaskType
}

struct AppTime: Codable, Hashable {
    let hour: Int
    let minute: Int
    
    static func fromDate(_ date: Date) -> Self {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return .init(hour: c.hour!, minute: c.minute!)
    }
}

struct AppDate: Codable, Hashable {
    let second: Int
    let minute: Int
    let hour: Int
    let day: Int
    let month: Int
    let year: Int
    
    static func fromDate(_ date: Date) -> Self {
        let c = Calendar.current.dateComponents([.day, .month, .year, .second, .minute, .hour], from: date)
        return .init(second: c.second!, minute: c.minute!, hour: c.hour!, day: c.day!, month: c.month!, year: c.year!)
    }
    
    static func now() -> Self {
        fromDate(Date())
    }
    
    func dateValue() -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)!
    }
}

struct AppTaskConfig: Identifiable, Codable, Hashable {
    var id: String
    let title: String
    let description: String
    var startingFrom: AppDate
    var completedDate: AppDate?
    let taskType: TaskType
    let creationDate: AppDate
    let imageValidation: Bool
    var onlyComment: Bool?
    let time: AppTime?
    let endTime: AppTime?
    let weekDays: [WeekDay]
    
    var onlyCommentBool: Bool {
        onlyComment ?? false
    }
    
    static func sortFunction(config1: AppTaskConfig, config2: AppTaskConfig) -> Bool {
        let time1 = config1.time
        let time2 = config2.time
        if time1 == nil || time2 == nil {
            if time1 == nil && time2 == nil {
                return config1.creationDate.dateValue().timeIntervalSince1970 < config2.creationDate.dateValue().timeIntervalSince1970
            }
            return time2 == nil
        }
        let value1 = time1!.hour*60+time1!.minute
        let value2 = time2!.hour*60+time2!.minute
        if value1 == value2 {
            let endTime1 = config1.endTime
            let endTime2 = config2.endTime
            if endTime1 == nil || endTime2 == nil {
                if endTime1 == nil && endTime2 == nil {
                    return config1.creationDate.dateValue().timeIntervalSince1970 < config2.creationDate.dateValue().timeIntervalSince1970
                }
                return endTime1 == nil
            }
            
            let endValue1 = endTime1!.hour*60+endTime1!.minute
            let endValue2 = endTime2!.hour*60+endTime2!.minute
            
            return endValue1 < endValue2
        }
        return value1 < value2
    }
    
    func getTasksCountData(tasks: [AppTask]) -> (targetCount: Int, completedCount: Int) {
        let start = startingFrom.dateValue()
        var endDate = Date()
        var toAdd = 0
        let completedDate = completedDate?.dateValue()
        if let completedDateValue = completedDate {
            endDate = completedDateValue
            toAdd = 1
        }
        let daysDiff = max(0, Calendar.current.differenceInDays(from: start, to: endDate)) + toAdd
        
        let circles = daysDiff / 7
        let remainder = daysDiff - circles*7
        
        let startWeekDay = Calendar.current.component(.weekday, from: start)
        let interval = WeekDay.getWeekDaysInterval(
            fromWeekDay: startWeekDay,
            toWeekDay: WeekDay.getWeekDayByAdding(value: remainder, to: startWeekDay)
        )
        let remainderCount = weekDays.filter { day in interval.contains(where: { $0 == day.value }) }.count
        
        let targetCount = circles*weekDays.count + remainderCount
        
        let completedCount = tasks.filter {
            completedDate != nil ||
            !Calendar.current.isDateInToday($0.completedDate.dateValue())
        }.count
        
        return (targetCount, completedCount)
    }
    
    func getTimeString() -> String {
        if let time {
            return "\(time.hour):\(String(format: "%02d", time.minute))"
        }
        return ""
    }
    
    func getEndTimeString() -> String {
        if let endTime {
            return "\(endTime.hour):\(String(format: "%02d", endTime.minute))"
        }
        return ""
    }
}

struct AppTask: Identifiable, Codable, Hashable {
    let id: String
    let completedDate: AppDate
    let imageUrls: [String]
    var comment: String
}

// получаем список всех конфигов и задач
// цикл -неделя 0 неделя item = date
// проверить вписывать ли конфиг по repeatInDays, startingFrom, item <= completedDate
