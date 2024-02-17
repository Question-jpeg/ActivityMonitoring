//
//  Date.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 08.02.2024.
//

import Foundation

extension Date {
    func toString() -> String {
        let weekday = Calendar.current.dateComponents([.weekday], from: self).weekday!
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .init(identifier: "ru_RU")
        dateFormatter.dateFormat = "d MMM yyyy"
        return WeekDay.getSelfFromValue(value: weekday).title + ", " + dateFormatter.string(from: self).capitalized
    }
}
