//
//  LicenseView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct LicenseView: View {
    var body: some View {
        // Text view
        VStack(alignment: .leading) {
            LicenseHTMLView()
            Spacer()
        }.frame(maxWidth: 500.0)
            .padding(.leading, 10.0)
            .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .background()
    }
}
