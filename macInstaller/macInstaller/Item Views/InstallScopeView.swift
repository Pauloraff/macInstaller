//
//  InstallScopeView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct InstallScopeView: View {
    @Bindable var model: InstallerState
    let choice: InstallScope
    
    init(model: InstallerState, choice: InstallScope) {
        self.model = model
        self.choice = choice
    }

    var body: some View {
        HStack {
            switch choice {
                case .allUsers:
                    Image(systemName: "desktopcomputer").resizable()
                        .frame(width: 32.0, height: 32.0)
                    Text("ALL_USERS").foregroundColor(Color(.labelColor))
                case .user:
                    Image(systemName: "person")
                        .resizable().frame(width: 32.0, height: 32.0)
                    Text("LOGGED_IN_USERS").foregroundColor(Color(.labelColor))
            }
            Spacer()
        }
    }
}
