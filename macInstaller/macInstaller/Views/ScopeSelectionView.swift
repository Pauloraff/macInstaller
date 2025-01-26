//
//  ScopeSelectionView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct ScopeSelectionView: View {
    @Binding var model: InstallerState
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("HOW_TO_INSTALL").padding(.leading, 10.0).padding(.trailing, 10.0).padding(.top, 20.0).padding(.bottom, 20.0)
            Divider()

            List(model.choices, id: \.self, selection: $model.selectedChoice) { item in
                InstallScopeView(model: model, choice: item)
                    .padding(.top, 10.0)
                    .padding(.bottom, 10.0)
                    .listRowBackground(model.selectedChoice == item ? Color.accentColor : Color.clear)
            }
            .listRowSeparator(.hidden)
            Divider()
            Spacer()
            
            // Installing this software requires XXX of disk space"
            let installSize: Int64 = model.scopeSizes[model.selectedChoice] ?? 0
            Text("INSTALL_SIZE \(installSize)")
            Text("")
            switch model.selectedChoice {
                case .allUsers:
                    Text("INSTALL_FOR_ALL_USERS")
                    // "You have chosen to install this software for all users of this computer"
                    Text("")
                case .user:
                    Text("INSTALL_FOR_CURRENT_USER")
                    //"You have chosen to install this software in your home folder")
                    // "Only the current user will be able to use this software"
                    Text("")
            }
        }.frame(maxWidth: 500.0)
            .padding(.leading, 10.0)
            .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .background(Color.white)
    }
}
