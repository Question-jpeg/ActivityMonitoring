//
//  ProfilesListView.swift
//  ActivityMonitoring
//
//  Created by Игорь Михайлов on 09.02.2024.
//

import SwiftUI

struct ProfilesListView: View {
    @EnvironmentObject var mainModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(mainModel.availableProfiles) { user in
                        NavigationLink {
                            ActivityViewerView(mainModel: mainModel, user: user)
                                .navigationBarBackButtonHidden()
                        } label: {
                            UserCell(user: user)
                        }
                    }
                    
                    if mainModel.availableProfiles.isEmpty {
                        Text("С вами ещё никто не делится своими планами")
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .appCardStyle(colors: [.blue, .purple])
                            .frame(height: UIScreen.height - 300)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
            }
            .navigationTitle("Мониторинг")
        }
        
    }
}

#Preview {
    ProfilesListView()
        .environmentObject(MainViewModel(authModel: AuthViewModel()))
}
