//
//  InstallerTaskView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

struct InstallerTaskView: View {
    let stateModel: InstallerTaskModel
    
    init(model: InstallerTaskModel) {
        self.stateModel = model
    }

    @State private var isRotating = 0.0

    var body: some View {
        HStack {
            switch stateModel.state {
                case .pending:
                    Image(systemName: "circle.dotted") // "circle.dotted"
                    Text(LocalizedStringKey(InstallerTaskNames[stateModel.task.rawValue]))
                    Spacer()
                case .running:
                    Image(systemName: "arrow.triangle.2.circlepath").bold().rotationEffect(.degrees(isRotating))
                        .onAppear {
                            withAnimation(.linear(duration: 1)
                                    .speed(0.1).repeatForever(autoreverses: false)) {
                                isRotating = 360.0
                            }
                        }
                    Text(LocalizedStringKey(InstallerTaskNames[stateModel.task.rawValue])).bold()
                    Spacer()
                case .skipped:
                    Image(systemName: "minus.circle").foregroundStyle(.gray)
                    Text(LocalizedStringKey(InstallerTaskNames[stateModel.task.rawValue])).foregroundStyle(.gray)
                    Spacer()
                case .completed:
                    Image(systemName: "checkmark.circle").foregroundStyle(.green)
                    Text(LocalizedStringKey(InstallerTaskNames[stateModel.task.rawValue])).foregroundStyle(.green)
                    Spacer()
                case .failed:
                    Image(systemName: "exclamationmark.circle").foregroundStyle(.red)
                    Text(LocalizedStringKey(InstallerTaskNames[stateModel.task.rawValue])).foregroundStyle(.red)
                    Spacer()
            }
                
        }
    }
}
