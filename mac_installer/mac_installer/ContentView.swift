//
//  ContentView.swift
//  mac_installer
//
//  Created by Paulo Raffaelli on 6/12/24.
//

import SwiftUI

enum InstallerStep: Int, CaseIterable {
    case introduction
    case license
    case installation
    case summary
    
    func getLabel() -> String {
        switch self {
            case .introduction:
                return "INTRODUCTION"
            case .license:
                return "LICENSE"
            case .installation:
                return "INSTALLATION"
            case .summary:
                return "SUMMARY"
        }
    }
}

enum InstallerSummary {
    case licenseRejected
    case installationSucceeded
    case failed
    case failedWithRollback
}

struct InstallerStepView: View {
    var current = InstallerStep.introduction
    var myself = InstallerStep.installation

    init(current: InstallerStep, myself: InstallerStep) {
        self.current = current
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
            if current.rawValue < myself.rawValue {
                Text(notyet).bold()
            } else if current.rawValue == myself.rawValue {
                Text(running).bold()
            } else {
                Text(done).bold()
            }
            Text(LocalizedStringKey(myself.getLabel())).bold().fontWeight(.semibold).padding(.bottom, 2.0)
        }
    }
}

enum InstallerTask: String {
    case requestAdminCredentials = "REQUEST_PERMISSIONS"   // if this fails, the install fails;
    // if it succeeds, the helper app is installed and launched with admin
    // permissions.
    case stopService = "STOP_SERVICE"               // detect whether the daemon is running (update install) or not (fresh install) and stop it if it is running.
    // stopService == 'sudo launctl unload <service identifier>
    case copyCurrentInstallation = "COPY_NEW_SERVICE"   // saves a copy of any files changed by the installation,
    // copies all required files to their destinations,
    // and if there is an error, undoes all the copies and leaves the file system
    // in the same state it was before copyCurrentInstallation ran.
    case startService = "START_SERVICE"              // start/restart the installed service.
    case cleanupPreviousInstallation = "CLEAN_UP_FILES" // remove any files that were part of the previous installation, if any.

    var body: some View {
        HStack {
            Text(LocalizedStringKey(rawValue))
        }
    }
}

struct InstallerState {
    var step: InstallerStep = .introduction
    var licenseAccepted = false // user must accept the license
    var freshInstall = true // If we detect a previous installation, set to false
    var permissionsGranted = false // Did the user enter admin credentials?
    var successful = false // This is set to true before the installation tasks are run
    var summaryMessage = ""
    
    mutating func gotoSummary() {
        if !licenseAccepted {
            summaryMessage = String(localized:"LICENSE_DECLINED") // user rejected license
        } else if successful {
            summaryMessage = String(localized:"INSTALL_SUCCEEDED") // install succeeded
        } else if freshInstall {
            summaryMessage = String(localized: "INSTALL_FAILED") // software not installed, not earlier version to fall back on
        } else {
            summaryMessage = String(localized: "INSTALL_ROLLBACK") // software not installed, previous version restored
        }
        step = .summary
    }
    
    mutating func gotoNext() {
        // test preconditions
        // -> license: always succeeds
        // -> Installation: user must accept license before continuing
        // The first install action is to prompt for permissions for the helper service
        // - if the user cancels, then the summary
        if let next = InstallerStep(rawValue:(step.rawValue + 1)) {
            step = next
        } else {
            // we got to the end
            NSApp.terminate(nil)
        }
    }
    mutating func gotoPrev() {
        if let prev = InstallerStep(rawValue:(step.rawValue - 1)) {
            step = prev
        }
    }
}


struct ContentView: View {
    @State private var model: InstallerState = InstallerState()

    func continueButtonClicked() {
        model.gotoNext()
    }
    
    func backButtonClicked() {
        model.gotoPrev()
    }
    
    func printButtonClicked() {
        // Print the license
    }
    
    func saveButtonClicked() {
        // Save the license to a file
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section: Title
            HStack {
                Spacer()
                Text("INSTALLER_TITLE").padding(.bottom, 5.0)
                Spacer()
            }
            // mid section:
            // left: vertical bullet points
            // right: main panel
            // bottom section: buttons (right-justified)
            HStack() {
                VStack(alignment: .leading) {
                    ForEach(InstallerStep.allCases, id: \.self) { step in
                        InstallerStepView(current: model.step, myself: step)
                    }
                    Spacer()
                }
                if (model.step == .introduction) {
                    VStack(alignment: .leading) {
                        Text("BRIEF_OVERVIEW")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("")
                        Text("DESCRIPTION")
                        Spacer()
                    }.frame(maxWidth: 500.0)
                        .padding(.leading, 10.0)
                        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                        .background(Color.white)
                }
                if (model.step == .license) {
                    // Text view
                    VStack(alignment: .leading) {
                        Text("LICENSE_TEXT").multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                if (model.step == .installation) {
                    // List of actions to undertake
                    // These all require that the helper service have been given permissions
                    VStack(alignment: .leading) {
                        Text("REQUEST_PERMISSIONS").multilineTextAlignment(.center)
                        Text("STOP_SERVICE").multilineTextAlignment(.center)
                        Text("COPY_NEW_SERVICE").multilineTextAlignment(.center)
                        Text("START_SERVICE").multilineTextAlignment(.center)
                        Text("CLEAN_UP_FILES").multilineTextAlignment(.center)
                        Text("RESTORE_SERVICE").multilineTextAlignment(.center).hidden()
                        Spacer()
                    }.layoutPriority(1).onAppear(perform: {
                        // fake install actions - delay five seconds, then fake a successful installation and transition to
                        // the summary screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            // Tell the model to go to the summary page.
                            model.gotoSummary()
                        }
                    })
                }
                if (model.step == .summary) {
                    // List of actions to undertake
                    VStack(alignment: .leading) {
                        if (model.successful) {
                            Text("SUMMARY_SUCCESS")
                        } else {
                            if (model.freshInstall) {
                                Text("SUMMARY_SUCCESS")
                            } else {
                                Text("SUMMARY_ROLLBACK")
                            }
                        }
                        Spacer()
                    }
                }
            }
            Text("")
            HStack {
                if (model.step == .license) {
                    Button(action: printButtonClicked) {
                        Text("PRINT")
                    }
                    Button(action: saveButtonClicked) {
                        Text("SAVE")
                    }
                }
                Spacer()
                if (model.step != .summary && 
                    model.step != .installation &&
                    model.step != .introduction) {
                    Button(action: backButtonClicked) {
                        Text("BACK").disabled(model.step == .introduction)
                    }
                }
                
                Button(action: continueButtonClicked) {
                    Text(model.step == .summary ? "DONE" : "CONTINUE")
                }.disabled(model.step == .installation)
            }
        }
        .padding()
        .onAppear(perform: {
            // perform startup initialization
        })
    }
}

#Preview {
    ContentView()
}
