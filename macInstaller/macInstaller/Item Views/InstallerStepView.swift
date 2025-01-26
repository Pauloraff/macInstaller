//
//  InstallerStepView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct InstallerStepView: View {
    @Bindable var model: InstallerState
    let myself: InstallerStep

    init(model: InstallerState, myself: InstallerStep) {
        self.model = model
        self.myself = myself
    }

    var done = AttributedString("●  ",
                                attributes: AttributeContainer().foregroundColor(Color(red:0, green:0, blue:0)))
    var running = AttributedString("●  ",
                                   attributes: AttributeContainer().foregroundColor(Color(red:0.7, green:0, blue:0.7)))
    var notyet = AttributedString("●  ",
                                attributes: AttributeContainer().foregroundColor(Color(red:0, green:0, blue:0)))

    var body: some View {
        HStack(spacing: 0) {
            if model.step.rawValue < myself.rawValue {
                Text(notyet).bold()
            } else if model.step.rawValue == myself.rawValue {
                Text(running).bold()
            } else {
                Text(done).bold()
            }
            Text(LocalizedStringKey(myself.getLabel())).bold().fontWeight(.semibold).padding(.bottom, 2.0)
        }
    }
}

