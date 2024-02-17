//
//  ThemeCustomizationView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 16.02.2024.
//

import SwiftUI

struct ThemeCustomizationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppThemeModel
    
    @State private var revealedPicker = 0
    @State private var counter1 = 0
    @State private var counter2 = 0
    @State private var counter3 = 0
    @State private var counter4 = 0
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.title)
                        .padding(.horizontal)
                }
                .tint(viewModel.theme.tint)
                
                Spacer()
                
                Text("Внешний вид")
                    .font(.title)
                
                Spacer()
                
                Image(systemName: "arrow.left")
                    .font(.title)
                    .padding(.horizontal)
                    .opacity(0)
            }
            .padding(.top)
            
            List {
                Section("Основной цвет") {
                    AppColorPicker(
                        isCollapsed: revealedPicker != 1,
                        onColorSelect: { viewModel.theme.tintCode = $0 },
                        selectedColor: viewModel.theme.tintCode) {
                            revealedPicker = revealedPicker == 1 ? 0 : 1
                        }
                }
                
                Section("Акцент") {                    
                    AppColorPicker(
                        isCollapsed: revealedPicker != 2,
                        onColorSelect: {
                            if $0 == viewModel.theme.accent1Code || $0 == viewModel.theme.accent2Code {
                                let temp = viewModel.theme.accent1Code
                                viewModel.theme.accent1Code = viewModel.theme.accent2Code
                                viewModel.theme.accent2Code = temp
                            } else {
                                if counter1 % 2 == 0 {
                                    viewModel.theme.accent1Code = $0
                                } else {
                                    viewModel.theme.accent2Code = $0
                                }
                                counter1 += 1
                            }
                        },
                        selectedColor: viewModel.theme.accent1Code,
                        selectedSecondColor: viewModel.theme.accent2Code
                    ) {
                        revealedPicker = revealedPicker == 2 ? 0 : 2
                    }
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [viewModel.theme.accent1, viewModel.theme.accent2],
                                             startPoint: .leading, endPoint: .trailing))
                }
                
                Section("Вторичный Акцент") {
                    AppColorPicker(
                        isCollapsed: revealedPicker != 3,
                        onColorSelect: {
                            if $0 == viewModel.theme.secAccent1Code || $0 == viewModel.theme.secAccent2Code {
                                let temp = viewModel.theme.secAccent1Code
                                viewModel.theme.secAccent1Code = viewModel.theme.secAccent2Code
                                viewModel.theme.secAccent2Code = temp
                            } else {
                                if counter2 % 2 == 0 {
                                    viewModel.theme.secAccent1Code = $0
                                } else {
                                    viewModel.theme.secAccent2Code = $0
                                }
                                counter2 += 1
                            }
                        },
                        selectedColor: viewModel.theme.secAccent1Code,
                        selectedSecondColor: viewModel.theme.secAccent2Code
                    ) {
                        revealedPicker = revealedPicker == 3 ? 0 : 3
                    }
                    
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [viewModel.theme.secAccent1, viewModel.theme.secAccent2],
                                             startPoint: .leading, endPoint: .trailing))
                }
                
                Section("Успех") {
                    AppColorPicker(
                        isCollapsed: revealedPicker != 4,
                        onColorSelect: {
                            if $0 == viewModel.theme.complete1Code || $0 == viewModel.theme.complete2Code {
                                let temp = viewModel.theme.complete1Code
                                viewModel.theme.complete1Code = viewModel.theme.complete2Code
                                viewModel.theme.complete2Code = temp
                            } else {
                                if counter3 % 2 == 0 {
                                    viewModel.theme.complete1Code = $0
                                } else {
                                    viewModel.theme.complete2Code = $0
                                }
                                counter3 += 1
                            }
                        },
                        selectedColor: viewModel.theme.complete1Code,
                        selectedSecondColor: viewModel.theme.complete2Code
                    ) {
                        revealedPicker = revealedPicker == 4 ? 0 : 4
                    }
                    
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [viewModel.theme.complete1, viewModel.theme.complete2],
                                             startPoint: .leading, endPoint: .trailing))
                }
                
                Section("Удаление") {
                    
                    AppColorPicker(
                        isCollapsed: revealedPicker != 5,
                        onColorSelect: {
                            if $0 == viewModel.theme.delete1Code || $0 == viewModel.theme.delete2Code {
                                let temp = viewModel.theme.delete1Code
                                viewModel.theme.delete1Code = viewModel.theme.delete2Code
                                viewModel.theme.delete2Code = temp
                            } else {
                                if counter4 % 2 == 0 {
                                    viewModel.theme.delete1Code = $0
                                } else {
                                    viewModel.theme.delete2Code = $0
                                }
                                counter4 += 1
                            }
                        },
                        selectedColor: viewModel.theme.delete1Code,
                        selectedSecondColor: viewModel.theme.delete2Code
                    ) {
                        revealedPicker = revealedPicker == 5 ? 0 : 5
                    }
                    
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [viewModel.theme.delete1, viewModel.theme.delete2],
                                             startPoint: .leading, endPoint: .trailing))
                }
                
                Section("Сменить тему") {
                    Button {
                        viewModel.toggleColorScheme()
                    } label: {
                        Text("Сменить тему")
                    }
                }
                
                Section("Подтверждение") {
                    
                    if viewModel.hasChanged {
                        Button {
                            viewModel.saveTheme()
                        } label: {
                            Text("Сохранить")
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [viewModel.theme.complete1, viewModel.theme.complete2])
                        }
                        
                        Button {
                            viewModel.revertTheme()
                        } label: {
                            Text("Вернуть")
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [viewModel.theme.secAccent1, viewModel.theme.secAccent2])
                        }
                    }
                    
                    if viewModel.hasInMemory {
                        Button {
                            viewModel.resetTheme()
                        } label: {
                            Text("Сбросить")
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [viewModel.theme.delete1, viewModel.theme.delete2])
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .buttonStyle(.borderless)
        }
        .animation(.default, value: revealedPicker)
    }
}

#Preview {
    ThemeCustomizationView()
        .environmentObject(AppThemeModel())
}

struct AppColorPicker: View {
    @EnvironmentObject var themeModel: AppThemeModel
    
    let isCollapsed: Bool
    let onColorSelect: (AppColor) -> Void
    let selectedColor: AppColor
    var selectedSecondColor: AppColor?
    let onReveal: () -> Void
    
    var body: some View {
        let upperI = isCollapsed ? AppColor.palletes.firstIndex(where: { p in
            p.contains(where: { $0 == selectedColor || $0 == selectedSecondColor })
        }) : 0
        ForEach(0..<AppColor.palletes.count, id: \.self) { i in
            let pallete = AppColor.palletes[i]
            if !isCollapsed || pallete.contains(where: { $0 == selectedColor || $0 == selectedSecondColor }) {
                HStack {
                    Text((i+1).formatted())
                        .foregroundStyle(.secondary)
                    ForEach(pallete, id: \.self) { appColor in
                        Button {
                            onColorSelect(appColor)
                        } label: {
                            Circle()
                                .fill(appColor.color)
                                .frame(width: 25)
                                .overlay {
                                    if appColor == selectedColor || appColor == selectedSecondColor {
                                        Image(systemName: selectedSecondColor == nil ? "checkmark" :
                                                appColor == selectedColor ? "1.circle" : "2.circle"
                                        )
                                        .foregroundStyle(.white)
                                        .font(.subheadline.bold())
                                        .shadow(radius: 1)
                                        .shadow(radius: 1)
                                        .shadow(radius: 1)
                                    }
                                }
                        }
                    }
                    
                    if i == upperI {
                        Button {
                            onReveal()
                        } label: {
                            Spacer()
                            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        }
                        .tint(themeModel.theme.tint)
                    }
                }
            }
        }
    }
}
