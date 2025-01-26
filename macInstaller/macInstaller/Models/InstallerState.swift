//
//  InstallerState.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

import SwiftUI

@Observable class InstallerState {
    var step: InstallerStep = .introduction
    var licenseAccepted = false // user must accept the license
    var freshInstall = true // If we detect a previous installation, set to false
    var permissionsGranted = false // Did the user enter admin credentials?
    var successful = false // This is set to true before the installation tasks are run
    var summaryMessage = ""
    var choices: [InstallScope] = []
    var selectedChoice: InstallScope
    var scopeSizes: [InstallScope:Int64]

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
        self.scopeSizes = [:]
        self.selectedChoice = .allUsers
    
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
                                if key == InstallScope.allUsers.rawValue || key == InstallScope.user.rawValue {
                                    if let scope = InstallScope(rawValue: key) {
                                        // calculate size of payload
                                        var payloadSize: Int64 = 0
                                        if let specificPayload = payloads[key] as? [String:Any] {
                                            if let specificFiles = specificPayload["Files"] as? [[String:String]] {
                                                for file in specificFiles {
                                                    if let dest = file["Filename"] {
                                                        // add size of file in Resources to payloadSize
                                                        let fileURL = payloadFolderURL.appending(component: key).appending(component: dest)
                                                        
                                                        if FileManager.default.fileExists(atPath: fileURL.path) {
                                                            do {
                                                                let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path) as [FileAttributeKey:Any]
                                                                let fileSize = attr[.size] as! Int64
                                                                payloadSize += fileSize
                                                            } catch {
                                                                
                                                            }
                                                        }
                                                        
                                                    }
                                                }
                                            }
                                        }
                                        scopeSizes[scope] = payloadSize
                                        self.choices.append(scope)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        self.choices.sort(by: { first, second in
            return first == .allUsers
        })
        if self.choices.count >= 1 {
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

    private func stepIsNotRelevant() -> Bool {
        // we skip over scope_select if there's only one scope available
        step == .scopeSelection && choices.count <= 1
    }
        
    func gotoNext() {
        // test preconditions
        // -> license: always succeeds
        // -> Installation: user must accept license before continuing
        // The first install action is to prompt for permissions for the helper service
        // - if the user cancels, then the summary
        if let next = InstallerStep(rawValue:(step.rawValue + 1)) {
            step = next

            if stepIsNotRelevant() {
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
 
            if stepIsNotRelevant() {
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
