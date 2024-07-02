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
    }

}
