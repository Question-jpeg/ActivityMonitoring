//
//  TaskCompletionDetailsView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI
import Kingfisher

struct TaskCompletionDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: TaskCompletionViewModel
    @EnvironmentObject var themeModel: AppThemeModel
    
    @State private var image: UIImage?
    @State private var showingCamera = false
    @FocusState private var isFocused: Bool
    
    let config: AppTaskConfig
    let editable: Bool
    let initialTask: AppTask?
    
    init(taskConfig: AppTaskConfig, task: AppTask? = nil, editable: Bool) {
        self.config = taskConfig
        self.editable = editable
        initialTask = task
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(config.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    
                Text(config.description)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            if !config.onlyComment {
                TabView {
                    ForEach(0..<(viewModel.createdUrls.isEmpty ?
                                 viewModel.images.count :
                                    viewModel.createdUrls.count), id: \.self) { i in
                        if !viewModel.createdUrls.isEmpty {
                            KFImage(URL(string: viewModel.createdUrls[i]))
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(uiImage: viewModel.images[i])
                                .resizable()
                                .scaledToFit()
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.images.remove(at: i)
                                    } label: {
                                        Text("Удалить")
                                    }
                                }
                        }
                    }
                }
                .tabViewStyle(.page)
                .onTapGesture { isFocused = false }
            }
            
            if (config.taskType == .tracker || viewModel.createdId == nil) && editable {
                if !config.onlyComment {
                    Button {
                        showingCamera = true
                        isFocused = false
                    } label: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 70)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                            }
                    }
                    .tint(themeModel.theme.tint)
                    .padding(.vertical, 10)
                }
                
                Button {
                    isFocused = true
                } label: {
                    TextEditor(text: $viewModel.comment)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                        .background(LinearGradient(colors: [
                            Color(.systemGray), Color(.systemGray3)
                        ], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 90)
                        .overlay {
                            if viewModel.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Комментарий")
                                    .foregroundStyle(.white)
                                    .allowsHitTesting(false)
                            }
                        }
                        .foregroundStyle(.white)
                }
                .tint(.white)
                .padding(.bottom, 10)
                
                HStack {
                    if !viewModel.loading {
                        Button {
                            dismiss()
                        } label: {
                            Text("Отмена")
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [themeModel.theme.accent1, themeModel.theme.accent2])
                        }
                    }
                    
                    Button {
                        if !config.onlyComment && viewModel.images.isEmpty {
                            viewModel.errorMessage = "Добавьте фотографии"
                        } else if config.onlyComment && viewModel.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.errorMessage = "Добавьте комментарий"
                        } else {
                            if let createdId = viewModel.createdId {
                                viewModel.setTaskProgress(id: createdId, configId: config.id, from: initialTask!.progress, value: initialTask!.progress+1, fromComment: initialTask!.comment, comment: initialTask!.comment.trimmedLineAppended(line: viewModel.comment), isSheet: true)
                            } else {
                                if config.taskType == .tracker { viewModel.comment = "".trimmedLineAppended(line: viewModel.comment) }
                                else { viewModel.comment = viewModel.comment.trimmingCharacters(in: .whitespacesAndNewlines) }
                                viewModel.createTask(configId: config.id, isSheet: true)
                            }
                        }
                    } label: {
                        Text("Выполнить")
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if viewModel.loading {
                                    HStack {
                                        ProgressView()
                                        Spacer()
                                        ProgressView()
                                    }
                                    .tint(.white)
                                }
                            }
                            .appCardStyle(colors: viewModel.loading ?
                                          [Color(.systemGray2), Color(.systemGray4)] :
                                            [themeModel.theme.complete1, themeModel.theme.complete2])
                    }
                }
                .padding(.bottom)
            } else {
                if !viewModel.comment.isEmpty {
                    Text(viewModel.comment)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(LinearGradient(colors:
                                                    [Color(.systemGray), Color(.systemGray3)],
                                                   startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.vertical)
                }
                
                HStack {
                    if editable && config.taskType != .tracker {
                        Button {
                            viewModel.deleteTask(id: viewModel.createdId!, configId: config.id, isSheet: true)
                        } label: {
                            Text("Удалить")
                                .frame(maxWidth: .infinity)
                                .overlay {
                                    if viewModel.loading {
                                        HStack {
                                            ProgressView()
                                            Spacer()
                                            ProgressView()
                                        }
                                        .tint(.white)
                                    }
                                }
                                .appCardStyle(colors: viewModel.loading ? [Color(.systemGray2), Color(.systemGray4)] : 
                                                [themeModel.theme.delete1, themeModel.theme.delete2])
                        }
                    }
                    if !viewModel.loading {
                        Button {
                            dismiss()
                        } label: {
                            Text("Вернуться")
                                .frame(maxWidth: .infinity)
                                .appCardStyle(colors: [themeModel.theme.secAccent1, themeModel.theme.secAccent2])
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.initState(task: initialTask, showComment: config.taskType != .tracker || !editable, dismiss: { dismiss() })
        }
        .animation(.default, value: isFocused)
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $image, sourceType: .camera) {
                if let uiimage = image {
                    viewModel.images.append(uiimage)
                }
            }
        }
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(title: Text(errorMessage))
        }
    }
}

#Preview {
    TaskCompletionDetailsView(
        taskConfig: MockData.taskConfig, editable: false)
    .environmentObject(TaskCompletionViewModel(mainModel: MainViewModel(authModel: AuthViewModel())))
}
