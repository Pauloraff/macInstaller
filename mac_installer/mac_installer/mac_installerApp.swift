//
//  mac_installerApp.swift
//  mac_installer
//
//  Created by Paulo Raffaelli on 6/12/24.
//

import SwiftUI


@main
struct mac_installerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .frame(minWidth: 640, maxWidth: 640, minHeight: 480, maxHeight: 480)
        }
        .windowResizability(.contentSize)
    }
    
    func viewDidLoad() {
        print("viewDidLoad")
        
// Milestone 2: request admin permissions for helper service
//        super.viewDidLoad()
//        
//        guard let auth = Util.askAuthorization() else {
//            NSApp.terminate(nil)
//            fatalError("Authorization not acquired.")
//        }
//        
//        if !Util.blessHelper(label: Constant.helperMachLabel, authorization: auth) {
//            NSApp.terminate(nil)
//            fatalError("User did not grant permissions to helper app")
//        }
//        
//        client.start()
    }

}
