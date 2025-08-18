//
//  SummaryView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct SummaryView: View {
    @Binding var model: InstallerState

    var body: some View {
        VStack(alignment: .leading) {
            if (model.successful) {
                Text("SUMMARY_SUCCESS").foregroundColor(Color(.labelColor))
            } else if (!model.permissionsGranted) {
                Text("PERMISSIONS_DECLINED").foregroundColor(Color(.labelColor))
            } else if (!model.licenseAccepted) {
                Text("LICENSE_DECLINED").foregroundColor(Color(.labelColor))
            } else if (model.freshInstall) {
                Text("INSTALL_FAILED").foregroundColor(Color(.labelColor))
            } else {
                Text("INSTALL_ROLLBACK").foregroundColor(Color(.labelColor))
            }
            Spacer()
        }.frame(maxWidth: 500.0)
            .padding(.leading, 10.0)
            .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .background()
    }
}

