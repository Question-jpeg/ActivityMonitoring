//
//  SuggestionsListView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 13.02.2024.
//

import SwiftUI

struct SuggestionsListView: View {
    
    @State private var tabIndex = 0
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    @State private var showingAssign = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Предложения")
                    .font(.title)
                    .padding(.top)
                
                HStack {
                    Button {
                        withAnimation(.default) {
                            tabIndex = 0
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(tabIndex == 0 ? themeModel.theme.tint : .gray)
                            .overlay(alignment: .bottom) {
                                if tabIndex == 0 {
                                    Rectangle()
                                        .fill(.secondary)
                                        .frame(height: 1)
                                        .offset(y: 5)
                                }
                            }
                    }
                    
                    Button {
                        withAnimation(.default) {
                            tabIndex = 1
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(tabIndex == 1 ? themeModel.theme.tint : .gray)
                            .overlay(alignment: .bottom) {
                                if tabIndex == 1 {
                                    Rectangle()
                                        .fill(.secondary)
                                        .frame(height: 1)
                                        .offset(y: 5)
                                }
                            }
                    }
                }
                .animation(.default, value: tabIndex)
                .tint(.primary)
                .padding(.top, 1)
                .padding(.bottom)
                
                TabView(selection: $tabIndex) {
                    SugListView(showingAssign: $showingAssign, suggestions: mainModel.gainingSuggestions, isGain: true)
                        .tag(0)
                    SugListView(showingAssign: $showingAssign, suggestions: mainModel.sentSuggestions)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.horizontal)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showingAssign = true
                } label: {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(themeModel.theme.tint)
                        .clipShape(Circle())
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showingAssign) {
                TaskConfigDetailsView(mainModel: mainModel, bottomPresenting: true, toAssign: true)
            }
        }
    }
}

#Preview {
    SuggestionsListView()
}

struct SugListView: View {
    @EnvironmentObject var mainModel: MainViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    @Binding var showingAssign: Bool
    
    let suggestions: [Suggestion]
    var isGain = false
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(suggestions) { suggestion in
                    NavigationLink(destination: {
                        TaskConfigDetailsView(mainModel: mainModel, initialTaskConfig: suggestion.config, toAssign: !isGain, suggestionId: suggestion.id)
                            .navigationBarBackButtonHidden()
                    }, label: {
                        SuggestionCell(suggestion: suggestion)                        
                    })
                    .tint(.primary)
                    .foregroundStyle(.primary)
                }
                
                if suggestions.isEmpty {
                    if !isGain {
                        Button {
                            showingAssign = true
                        } label: {
                            Text("Назначить задачу")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
                                .padding(.horizontal)
                        }
                        .frame(height: UIScreen.height - 300)
                    } else {
                        Text("Нет предложенных задач")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(height: UIScreen.height - 300)
                    }
                }
            }
        }
    }
}
