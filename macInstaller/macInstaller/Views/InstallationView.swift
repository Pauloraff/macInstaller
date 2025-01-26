//
//  InstallationView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

let delayBetweenTasks: TimeInterval = 1.0
let delayAfterLastTask: TimeInterval = 2.0

struct InstallationView: View {
    @Binding var model: InstallerState

    var body: some View {
        // List of actions to undertake
        // These all require that the helper service have been given permissions
        VStack(alignment: .leading) {
            ForEach(model.stages) { stage in
                InstallerTaskView(model: stage)
            }
            Spacer()
        }.frame(maxWidth: 500.0)
            .padding(.leading, 10.0)
            .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .background(Color.white)
            .onAppear(perform: {
                // run the next task
                runNextAvailableTask()
            })
   }
    
    func runNextAvailableTask() {
        // The manifestURL points to the file in the app bundle that is the PayloadMetadata.plist;
        // all the other files in the payload are in the same directory in the app bundle.
        if let next = model.stages.first(where: { $0.state == .pending }), let manifestURL = bundleURL(fileName: "PayloadMetadata", fileExtension: "plist") {
            // we tell the client to perform a task
            // note that this requires that the user have chosen an install scope -
            //
            let choice = model.selectedChoice
            
            model.begin(what: next)
            switch next.task {
                case .stopService:
                    client.stopService(manifestURL, choice.rawValue) { result in
                        handleCompletedTask(result)
                    }
                case .copyNewService:
                    // We pass the path of the metadata file to the service
                    client.copyNewService(manifestURL, choice.rawValue) { result in
                        handleCompletedTask(result)
                    }
                case .startService:
                    client.startService(manifestURL, choice.rawValue) { result in
                        handleCompletedTask(result)
                    }
                case .cleanUpFiles:
                    client.cleanupFiles(manifestURL, choice.rawValue) { result in
                        handleCompletedTask(result)
                    }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayAfterLastTask) {
                model.gotoSummary()
            }
        }
    }

    func handleCompletedTask(_ result: Bool) {
        if result {
            model.handle(result: result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenTasks) {
                runNextAvailableTask()
            }
        } else {
            model.handle(result: result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayAfterLastTask) {
                model.gotoSummary()
            }
        }
    }
}

