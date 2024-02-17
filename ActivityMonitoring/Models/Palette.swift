//
//  AppColor.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 16.02.2024.
//

import SwiftUI

enum AppColor: String, Codable {
    case d1, d2, d3, d4, d5, d6,
         p11, p12, p13, p14, p15,
         p21, p22, p23, p24, p25,
         p31, p32, p33, p34, p35,
         p41, p42, p43, p44, p45,
         p51, p52, p53, p54, p55,
         p61, p62, p63, p64, p65
    
    var color: Color {
        AppColor.colors[self]!
    }
    
    static let colors: [AppColor: Color] = [
        .d1: .purple,
        .d2: .green,
        .d3: .cyan,
        .d4: .red,
        .d5: .orange,
        .d6: .blue,
        
        .p11: ._1_1,
        .p12: ._1_2,
        .p13: ._1_3,
        .p14: ._1_4,
        .p15: ._1_5,
        
        .p21: ._2_1,
        .p22: ._2_2,
        .p23: ._2_3,
        .p24: ._2_4,
        .p25: ._2_5,
        
        .p31: ._3_1,
        .p32: ._3_2,
        .p33: ._3_3,
        .p34: ._3_4,
        .p35: ._3_5,
        
        .p41: ._4_1,
        .p42: ._4_2,
        .p43: ._4_3,
        .p44: ._4_4,
        .p45: ._4_5,
        
        .p51: ._5_1,
        .p52: ._5_2,
        .p53: ._5_3,
        .p54: ._5_4,
        .p55: ._5_5,
        
        .p61: ._6_1,
        .p62: ._6_2,
        .p63: ._6_3,
        .p64: ._6_4,
        .p65: ._6_5,
    ]
    
    static let palletes: [[Self]] = [
        [.d1, .d2, .d3, .d4, .d5, .d6],
        [.p11, .p12, .p13, .p14, .p15],
        [.p21, .p22, .p23, .p24, .p25],
        [.p31, .p32, .p33, .p34, .p35],
        [.p41, .p42, .p43, .p44, .p45],
        [.p51, .p52, .p53, .p54, .p55],
        [.p61, .p62, .p63, .p64, .p65]
    ]
}

struct AppTheme: Codable, Equatable {
    var tintCode: AppColor = .d1
    var complete1Code: AppColor = .d2
    var complete2Code: AppColor = .d3
    var delete1Code: AppColor = .d4
    var delete2Code: AppColor = .d1
    var accent1Code: AppColor = .d4
    var accent2Code: AppColor = .d5
    var secAccent1Code: AppColor = .d6
    var secAccent2Code: AppColor = .d1
    
    var tint: Color { tintCode.color }
    var complete1: Color { complete1Code.color }
    var complete2: Color { complete2Code.color }
    var delete1: Color { delete1Code.color }
    var delete2: Color { delete2Code.color }
    var accent1: Color { accent1Code.color }
    var accent2: Color { accent2Code.color }
    var secAccent1: Color { secAccent1Code.color }
    var secAccent2: Color { secAccent2Code.color }
}
