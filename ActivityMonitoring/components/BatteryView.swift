//
//  BatteryView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 12.02.2024.
//

import SwiftUI

struct BatteryView: View {
    let targetCount: Int
    let completedCount: Int
    var flex = false
    
    var color: Color {
        Color.interpolate(colors: [.red, .yellow, .green], value: percentage)
    }
    
    var percentage: Double {
        if targetCount != 0 {
            return Double(completedCount) / Double(targetCount)
        }
        
        return 0
    }
    
    var body: some View {
        if targetCount != 0 {
            HStack(spacing: 0) {
                if flex {
                    Text("Рейтинг")
                        .padding(.trailing, 5)
                }
                
                Text(Int(percentage*100).formatted())
                    .fontWeight(.bold)
                
                Text("%")
                    .font(.footnote)
            }
            .frame(maxWidth: flex ? .infinity : 50)
            .shadow(color: .black, radius: 0.5)
            .shadow(color: .black, radius: 0.5)
            .shadow(color: .black, radius: 0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .background(
                GeometryReader { geo in
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width*percentage)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5).stroke(color, lineWidth: 1.5)
            }
        }
    }
}

#Preview {
    BatteryView(targetCount: 2, completedCount: 1)
}
