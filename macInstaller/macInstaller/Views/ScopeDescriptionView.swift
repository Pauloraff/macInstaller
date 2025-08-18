//
//  ScopeDescriptionView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct ScopeDescriptionView: View {
    @Binding var model: InstallerState

    var body: some View {
        VStack(alignment: .leading) {
            let installSize: Int64 = model.scopeSizes[model.selectedChoice] ?? 0
            Text("INSTALL_SIZE \(installSize)").foregroundColor(Color(.labelColor))
            Text("")
            switch model.selectedChoice {
                case .allUsers:
                    Text("ALL_USERS_CAN_USE").foregroundColor(Color(.labelColor))
                    Text("")
                case .user:
                    Text("CURRENT_USER_CAN_USE").foregroundColor(Color(.labelColor))
                    Text("")
            }
            // Click Install to perform a standard installation in your home folder. Only the current user of this computer will be able to use this software.
            
            // This will take xxx of space on your computer.
            //
            // Click Install to perform a standard installation of this software for all users of this computer. All users of this computer will be able to use this software.
            
            Spacer()
        }.frame(maxWidth: 500.0)
            .padding(.leading, 10.0)
            .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .background()
    }
}
