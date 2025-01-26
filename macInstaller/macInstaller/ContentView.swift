//
//  ContentView.swift
//  mac_installer
//
//  Created by Paulo Raffaelli on 6/12/24.
//

import SwiftUI
import WebKit

// Needs to be shared with the InstallationView, which does the actual installation
var client = XPCClient()

struct ContentView: View {
    @State var model: InstallerState = InstallerState(step: .introduction)
    @State var singleSelection: InstallScope = .allUsers
    @State var showModal: Bool = false
    
    func continueButtonClicked() {
        if model.step == .license {
            showModal = true
        } else {
            model.gotoNext()
        }
    }
    
    // .scopeSelection
    func backButtonClicked() {
        model.gotoPrev()
        if model.step == .awaitingLicenseAcceptance {
            model.gotoPrev()
        }
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
                    if model.choices.count <= 1 {
                        let allExcept = InstallerStep.allCases.filter { step in (step != InstallerStep.scopeSelection) && (step != .awaitingLicenseAcceptance) }
                        ForEach(allExcept, id: \.self) { step in
                            InstallerStepView(model: model, myself: step)
                        }
                    } else {
                        let allExceptAwaiting = InstallerStep.allCases.filter { step in (step != .awaitingLicenseAcceptance) }
                        ForEach(allExceptAwaiting, id: \.self) { step in
                            InstallerStepView(model: model, myself: step)
                        }
                    }
                    Spacer()
                }
                
                // Note that this leaks views if the user navigates back and forth repeatedly.
                switch model.step {
                    case .introduction: IntroductionView().body
                    case .license: LicenseView().body
                    case .scopeSelection: ScopeSelectionView(model: $model).body
                    case .scopeDescription: ScopeDescriptionView(model: $model).body
                    case .installation: InstallationView(model: $model).body
                    case .summary: SummaryView(model: $model).body
                    case .awaitingLicenseAcceptance:
                        Text("") // placeholder, this view is not shown
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
                    model.step != .awaitingLicenseAcceptance &&
                    model.step != .introduction) {
                    Button(action: backButtonClicked) {
                        Text("BACK").disabled(model.step == .introduction)
                    }
                }
                
                Button(action: continueButtonClicked) {
                    Text(model.step == .summary ? "DONE" : "CONTINUE")
                }.disabled(model.step == .installation || model.step == .awaitingLicenseAcceptance)
            }
        }
        .padding()
        .onAppear(perform: {
            // perform startup initialization
            guard let auth = Util.askAuthorization() else {
                fatalError("Authorization not acquired.")
            }
            
            if (!Util.blessHelper(label: Constant.helperMachLabel, authorization: auth)) {
                // we go immediately to the summary screen, and the only option is to exit.
                model.gotoSummary()
            } else {
                model.permissionsGranted = true
                client.start()
            }
        })
        .alert(isPresented: $showModal) {
            Alert(
                title: Text(""),
                message: Text("ACCEPT_TEXT"),
                primaryButton: Alert.Button.default(Text("REJECT"), action: {
                    model.successful = false
                    model.licenseAccepted = false
                    model.step = .summary
                    showModal = false
                }),
                secondaryButton: Alert.Button.destructive(Text("ACCEPT"), action: {
                    model.successful = true
                    model.licenseAccepted = true
                    model.step = model.choices.count <= 1 ? .scopeDescription : .scopeSelection
                    showModal = false
                })
            )
        }
    }
}
