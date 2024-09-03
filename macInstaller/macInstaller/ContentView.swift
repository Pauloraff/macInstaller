//
//  ContentView.swift
//  mac_installer
//
//  Created by Paulo Raffaelli on 6/12/24.
//

import SwiftUI
import WebKit

enum InstallerStep: Int, CaseIterable {
    case introduction
    case license
    case awaitingLicenseAcceptance
    case scopeSelection
    case scopeDescription
    case installation
    case summary
    
    func getLabel() -> String {
        switch self {
            case .introduction:
                return "INTRODUCTION"
            case .license:
                return "READ_LICENSE"
            case .awaitingLicenseAcceptance:
                return "ACCEPT_LICENSE"
            case .scopeSelection:
                return "SCOPE_SELECT"
            case .scopeDescription:
                return "SCOPE_DESCRIBE"
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

let InstallerTaskNames = [
    "NO MATCH",
    "STOP_SERVICE" ,
    "COPY_NEW_SERVICE",
    "START_SERVICE",
    "CLEAN_UP_FILES"
]

enum InstallerTask: Int {
    case stopService = 1 // "STOP_SERVICE"               // detect whether the daemon is running (update install) or not (fresh install) and stop it if it is running.
    // stopService == 'sudo launctl unload <service identifier>
    case copyNewService = 2 // "COPY_NEW_SERVICE"   // saves a copy of any files changed by the installation,
    // copies all required files to their destinations,
    // and if there is an error, undoes all the copies and leaves the file system
    // in the same state it was before copyCurrentInstallation ran.
    case startService = 3 // "START_SERVICE"              // start/restart the installed service.
    case cleanUpFiles = 4 // "CLEAN_UP_FILES" // remove any files that were part of the previous installation, if any.
}

enum InstallerTaskState: Int {
    case pending = 1
    case running = 2
    case completed = 3
    case failed = 4
    case skipped = 5
}

struct InstallerTaskModel: Identifiable {
    let task: InstallerTask
    let state: InstallerTaskState
    
    var id: Int { task.rawValue << 4 | state.rawValue  }
}

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

func bundleURL(fileName: String, fileExtension: String) -> URL? {
    if let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
        return fileURL
    } else {
        print("File not found")
        return nil
    }
}

@Observable class InstallerState {
    var step: InstallerStep = .introduction
    var licenseAccepted = false // user must accept the license
    var freshInstall = true // If we detect a previous installation, set to false
    var permissionsGranted = false // Did the user enter admin credentials?
    var successful = false // This is set to true before the installation tasks are run
    var summaryMessage = ""
    var choices: [String] = []
    var selectedChoice: String?
    
    var stages: [InstallerTaskModel] = [
        InstallerTaskModel( task: InstallerTask.stopService, state: InstallerTaskState.pending ),
        InstallerTaskModel( task: InstallerTask.copyNewService, state: InstallerTaskState.pending ),
        InstallerTaskModel( task: InstallerTask.startService, state: InstallerTaskState.pending ),
        InstallerTaskModel( task: InstallerTask.cleanUpFiles, state: InstallerTaskState.pending )
    ]

    init(step: InstallerStep, licenseAccepted: Bool = false, freshInstall: Bool = true, permissionsGranted: Bool = false, successful: Bool = false, summaryMessage: String = "") {
        self.step = step
        self.licenseAccepted = licenseAccepted
        self.freshInstall = freshInstall
        self.permissionsGranted = permissionsGranted
        self.successful = successful
        self.summaryMessage = summaryMessage
        
        self.choices = []
        
        // set up the set of installer scenarios. If there is only one, then we don't
        // present the screen where the user is given a choice.
        if let manifestURL = bundleURL(fileName: "PayloadMetadata", fileExtension: "plist") {
            let payloadFolderURL = manifestURL.deletingLastPathComponent()

            if let data = try? Data(contentsOf: manifestURL) {
                if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                    if let dict = result as? [String:Any] {
                        if let payloads = dict["Payloads"] as? [String:Any] {
                            let keys = payloads.keys.map { $0 as String }
                            for key in keys {
                                if key == "System" || key == "AllUsers" || key == "User" {
                                    self.choices.append(key)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if self.choices.count == 1 {
            self.selectedChoice = self.choices[0]
        }
    }
    
    func gotoSummary() {
        if !permissionsGranted {
            summaryMessage = String(localized:"PERMISSIONS_DECLINED") // user did not grant background service permissions
        } else if !licenseAccepted {
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
    
    func gotoNext() {
        // test preconditions
        // -> license: always succeeds
        // -> Installation: user must accept license before continuing
        // The first install action is to prompt for permissions for the helper service
        // - if the user cancels, then the summary
        if let next = InstallerStep(rawValue:(step.rawValue + 1)) {
            step = next
            // we skip over scope_select if there's only one scope available
            if step == .scopeSelection && choices.count <= 1 {
                if let next = InstallerStep(rawValue:(step.rawValue + 1)) {
                    step = next
                }
            }
        } else {
            // we got to the end
            NSApp.terminate(nil)
        }
    }

    func gotoPrev() {
        if let prev = InstallerStep(rawValue:(step.rawValue - 1)) {
            step = prev
            
            if step == .scopeSelection && choices.count <= 1 {
                if let prev = InstallerStep(rawValue:(step.rawValue - 1)) {
                    step = prev
                }
            }
        }
    }
    
    func begin(what: InstallerTaskModel) {
        let stepIndex = stages.firstIndex(where: { stage in stage.task == what.task && stage.state == .pending})
        if let stepIndex = stepIndex {
            let removed = stages.remove(at: stepIndex)
            stages.insert(InstallerTaskModel(task: removed.task, state: .running), at: stepIndex)
        }
    }

    func handle(result: Bool) {
        if result {
            let stepIndex = stages.firstIndex(where: { stage in stage.state == .running})

            if let stepIndex = stepIndex {
                let removed = stages.remove(at: stepIndex)
                stages.insert(InstallerTaskModel(task: removed.task, state: .completed), at: stepIndex)
            }
        } else {
            successful = false
            
            stages = stages.map { item in
                if item.state == .running {
                    return InstallerTaskModel(task: item.task, state: .completed)
                } else if item.state == .pending {
                    return InstallerTaskModel(task: item.task, state: .skipped)
                } else {
                    return item
                }
            }
        }
    }
}

class WebViewData: ObservableObject {
  @Published var loading: Bool = false
  @Published var url: URL?;

  init (url: URL) {
    self.url = url
  }
}

struct ContentView: View {
    var client = XPCClient()
    @State var model: InstallerState = InstallerState(step: .introduction)

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
        
    func handleCompletedTask(_ result: Bool) {
        if result {
            model.handle(result: result)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                runNextAvailableTask()
            }
        } else {
            model.handle(result: result)

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                // Tell the model to go to the summary page.
                model.gotoSummary()
            }
        }
    }
    
    func runNextAvailableTask() {
        // The manifestURL points to the file in the app bundle that is the PayloadMetadata.plist;
        // all the other files in the payload are in the same directory in the app bundle.
        if let next = model.stages.first(where: { $0.state == .pending }), let manifestURL = bundleURL(fileName: "PayloadMetadata", fileExtension: "plist") {
            // we tell the client to perform a task
            model.begin(what: next)
            switch next.task {
                case .stopService:
                    client.stopService(manifestURL, model.selectedChoice ?? "") { result in
                         handleCompletedTask(result)
                    }
                case .copyNewService:
                    // We pass the path of the metadata file to the service
                    client.copyNewService(manifestURL, model.selectedChoice ?? "") { result in
                        handleCompletedTask(result)
                    }
                case .startService:
                    client.startService(manifestURL, model.selectedChoice ?? "") { result in
                        handleCompletedTask(result)
                    }
                case .cleanUpFiles:
                    client.cleanupFiles(manifestURL, model.selectedChoice ?? "") { result in
                        handleCompletedTask(result)
                    }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                // Tell the model to go to the summary page.
                model.gotoSummary()
            }
        }
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
                        let allExcept = InstallerStep.allCases.filter { step in step != InstallerStep.scopeSelection }
                        ForEach(allExcept, id: \.self) { step in
                            InstallerStepView(current: model.step, myself: step)
                        }
                    } else {
                        ForEach(InstallerStep.allCases, id: \.self) { step in
                            InstallerStepView(current: model.step, myself: step)
                        }
                    }
                    Spacer()
                }
                if model.step == .introduction {
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
                        LicenseHTMLView()
                        Spacer()
                    }.frame(maxWidth: 500.0)
                        .padding(.leading, 10.0)
                        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                        .background(Color.white)
                }
                if model.step == .awaitingLicenseAcceptance {
                    AcceptanceView().environment(model)
                }
                if model.step == .scopeSelection {
                    VStack(alignment: .leading) {
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
                if model.step == .scopeDescription {
                    VStack(alignment: .leading) {
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
                if model.step == .installation {
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

                if (model.step == .summary) {
                     VStack(alignment: .leading) {
                        if (model.successful) {
                            Text("SUMMARY_SUCCESS")
                        } else if (!model.permissionsGranted) {
                            Text("PERMISSIONS_DECLINED")
                        } else if (!model.licenseAccepted) {
                            Text("LICENSE_DECLINED")
                        } else if (model.freshInstall) {
                            Text("INSTALL_FAILED")
                        } else {
                            Text("INSTALL_ROLLBACK")
                        }
                        Spacer()
                    }.frame(maxWidth: 500.0)
                        .padding(.leading, 10.0)
                        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                        .background(Color.white)
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
    }
}

struct AcceptanceView: View {
    @Environment(InstallerState.self) private var model
    
    var body: some View {
        VStack {
            Text("ACCEPT_TEXT")
            Spacer()
            HStack {
                Button("REJECT") {
                    model.successful = false
                    model.licenseAccepted = false
                    model.step = .summary
                }
                Button("ACCEPT") {
                    model.successful = true
                    model.licenseAccepted = true
                    model.step = model.choices.count <= 1 ? .scopeDescription : .scopeSelection
                }
            }

        }
    }
}

#Preview {
    ContentView(model: InstallerState(step: .installation, licenseAccepted: false, freshInstall: true, permissionsGranted: false, successful: false, summaryMessage: ""))
}
