//
//  Color.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 10.02.2024.
//

import SwiftUI

extension Color {
    func getComponents() -> (red: Double, green: Double, blue: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue)
    }
    
    static func interpolate(colors: [Color], value: Double) -> Color {
        let middleIndex = value * Double(colors.count-1)
        let fromIndex = Int(floor(middleIndex))
        let toIndex = Int(ceil(middleIndex))
        let interpolation = middleIndex - Double(fromIndex)
        
        let (red, green, blue) = colors[fromIndex].getComponents()
        let (redTo, greenTo, blueTo) = colors[toIndex].getComponents()
        
        return Color(uiColor: UIColor(
            red: red+interpolation*(redTo-red),
            green: green+interpolation*(greenTo-green),
            blue: blue+interpolation*(blueTo-blue),
            alpha: 1
        ))
    }
}
