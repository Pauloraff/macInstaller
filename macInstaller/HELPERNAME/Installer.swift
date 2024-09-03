import Foundation

class InstallerImpl: NSObject, Installer {
    var client: InstallationClient?
    
    let restoreFolder = "/tmp/macInstaller"
    // utility method
    // load URL (file) into a dictionary
    // Metadata is in the same folder in the app bundle as all of the files to be copied,
    // so we can check that all the filenames in the payload metadata match files in the
    // app bundle.
    // Dictionary
    // -> BundleID: String
    // -> Payloads: [String:[String:[[String:String]]]]
    // -> -> "System": [String:[[String:String]]]
    // -> -> -> "Files": [[String:String]]
    func loadManifest(_ manifestURL: URL, _ context: String) -> [String:Any]? {
        let payloadFolderURL = manifestURL.deletingLastPathComponent()

        if let data = try? Data(contentsOf: manifestURL) {
            if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                if let dict = result as? [String:Any] {
                    // check dict
                    // Key 'BundleID' exists and is of the form (\w\.)+\w
                    guard let bundleID = dict["BundleID"] as? String else {
                        return nil
                    }
                    guard let payloads = dict["Payloads"] as? [String:[String:[[String:String]]]] else {
                        return nil
                    }
                    guard let contextFiles = payloads[context] else {
                        return nil
                    }
                    guard let files = contextFiles["Files"] else {
                        return nil
                    }
                    guard let _ =  bundleID.wholeMatch(of: /^(\w+\.)+(\w)+$/) else {
                        return nil
                    }

                    for entry in files {
                        if let dest = entry["Destination"]  {
                            // must start with '/' and must have at least one other character
                            if dest.count <= 1 || !dest.hasPrefix("/") || !dest.hasSuffix("/") {
                                return nil
                            }
                        } else {
                            return nil
                        }
                        if let owner = entry["OwnerGroup"] {
                            if owner != "root:wheel" {
                                return nil
                            }
                        } else {
                            return nil
                        }
                        if let dest = entry["Filename"] {
                            let fileURL = payloadFolderURL.appending(component: dest)
                            
                            if !FileManager.default.fileExists(atPath: fileURL.path) {
                               return nil
                            }
                        } else {
                            return nil
                        }
                        if let dest = entry["Permissions"] {
                            // must be 10 characters long
                            if dest.lengthOfBytes(using: .ascii) != 10 {
                                return nil
                            }

                            for (index, item) in dest.enumerated() {
                                // first character must be '-'
                                if index == 0 && item != "-" {
                                   return nil
                                }
                                // [1], [4], [7] must be 'r' or '-'
                                // [2], [5], [8] must be 'w' or '-'
                                // [3], [6], [9] must be 'x' or '-'
                                switch index % 3 {
                                    case 1: if item != "-" && item != "r" { return nil } // 'r' || '-'
                                    case 2: if item != "-" && item != "w" { return nil } // 'r' || '-'
                                    case 0: if item != "-" && item != "x" { return nil } // 'x' || '-'
                                    default:
                                        return nil
                                }
                            }
                        } else {
                            return nil
                        }
                    }
                    return dict
                }
           }
        }
        
        return nil
    }
    // System-level service:
    // /usr/bin/sudo /bin/launchctl bootout system/PRODUCTNAME (BundleID in manifestURL)
    // Detect:
    // /usr/bin/sudo /bin/launchctl list: loop over lines looking for
    func stopService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ()) {
        // load the file indicated by manifestURL
        guard let manifest = loadManifest(manifestURL, context) else {
            completion(false)
            return
        }
        guard let bundleID = manifest["BundleID"] as? String else {
            completion(false)
            return
        }
        let url = URL(fileURLWithPath:"/usr/bin/sudo")
        do {
            let args = ["/bin/launchctl", "bootout", "system/\(bundleID)"]
            try Process.run(url, arguments: args) { (process) in
                NSLog("\ndidFinish: \(!process.isRunning)")
                let status = process.terminationStatus
                Thread.sleep(forTimeInterval: 1.0)
                completion(status == 0 || status == 3) // 0: success, 3: service not found
            }
        } catch {
            NSLog("\nProcess.run failed")
            completion(false)
        }
    }
    
    func copyNewService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ()) {
        guard let manifest = loadManifest(manifestURL, context) else {
            completion(false)
            return
        }
        guard let payloads = manifest["Payloads"] as? [String:[String:[[String:String]]]] else {
            completion(false)
            return
        }
        guard let contextFiles = payloads[context] else {
            completion(false)
            return
        }
        guard let fileList = contextFiles["Files"] else {
            completion(false)
            return
        }
        // fileList should be OK because SetupPayloadMetadata.zsh checks the format
        // walk through manifest and collect all paths
        let pathSet = Set(fileList.map {
            fileMetadata in 
            return URL(fileURLWithPath: "\(restoreFolder)\(fileMetadata["Destination"]!)", isDirectory: true)
        })
        // (re)create a temporary dir: /tmp/macInstaller/
        let tempDir = URL(fileURLWithPath: restoreFolder, isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            completion(false)
            return
        }
        // create all the subdirectories needed ('paths' is a set, so each dir is only created once)
        // for each file in manifest:
        for path in pathSet {
            do {
                try FileManager.default.createDirectory(at: path.absoluteURL, withIntermediateDirectories: true)
            } catch {
                completion(false)
                return
            }

        }
        
        var success = true
        
        for fileMetadata in fileList {
            let destFilePath = "\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!)"
            let savedFilePath = "\(restoreFolder)\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!))"
            // If the file already exists at 'dest', move it to /tmp/xxx/path/to/dest/file
            if FileManager.default.fileExists(atPath: destFilePath) {
               // move to savedFilePath
                do {
                    try FileManager.default.moveItem(atPath: destFilePath, toPath: savedFilePath)
                } catch {
                    success = false
                    break
                }
            }
        }
        
        let payloadFolderURL = manifestURL.deletingLastPathComponent()
        if success {
            //   for each file in manifest:
            //      copy new version of file to /path/to/dest/file and set permissions
            //      if failure, remove /path/to/dest/file, mark task as failed and break
            //   end
            for fileMetadata in fileList {
                let sourceFilePath = "\(payloadFolderURL.path)/\(fileMetadata["Filename"]!)"
                let destFilePath = "\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!)"
                
                // copy sourceFilePath to destFilePath
                do {
                    try FileManager.default.copyItem(atPath: sourceFilePath, toPath: destFilePath)
                    
                    // set permissions and owner:group
                    var perms: Int16 = 0
                    let permissions = fileMetadata["OwnerGroup"]!.components(separatedBy: ":")
                    
                    let permString = fileMetadata["Permissions"]!.utf8CString
                    let dash: Int8 = 45 // '-' character
                    // owner
                    perms |= permString[1] == dash ? 0 : 0o400
                    perms |= permString[2] == dash ? 0 : 0o200
                    perms |= permString[3] == dash ? 0 : 0o100
                    // group
                    perms |= permString[4] == dash ? 0 : 0o040
                    perms |= permString[5] == dash ? 0 : 0o020
                    perms |= permString[6] == dash ? 0 : 0o010
                    // other
                    perms |= permString[7] == dash ? 0 : 0o004
                    perms |= permString[8] == dash ? 0 : 0o002
                    perms |= permString[9] == dash ? 0 : 0o001

                    
                    let attributes: [FileAttributeKey:Any] = [
                        .ownerAccountName:permissions[0],
                        .groupOwnerAccountName:permissions[1],
                        .posixPermissions: NSNumber(value: perms)
                    ]
                    // groupOwnerAccountName: "wheel"
                    // ownerAccountName: "root"
                    
                    try FileManager.default.setAttributes(attributes, ofItemAtPath: destFilePath)
                } catch {
                    success = false
                    break
                }
            }
        }
        
        if !success {
            //   for each file in manifest:
            //     if /tmp/xxx/path/to/dest/file exists:
            //       copy to /path/to/dest/file and set perms to match /tmp/xxx/path/to/dest/file
            //     end
            //   end
            for fileMetadata in fileList {
                let destFilePath = "\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!)"
                let savedFilePath = "\(restoreFolder)\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!))"
                // If the file already exists at 'dest', remove it and restore from /tmp/xxx/path/to/dest/file
                if FileManager.default.fileExists(atPath: destFilePath) {
                    do {
                        try FileManager.default.removeItem(atPath: destFilePath)
                    } catch {
                        success = false
                        break
                    }
                    // restore from savedFilePath
                    do {
                        try FileManager.default.moveItem(atPath: savedFilePath, toPath: destFilePath)
                    } catch {
                        success = false
                        break
                    }
                }
            }

            do {
                try FileManager.default.removeItem(atPath: restoreFolder)
            } catch {
                success = false
            }
        }
        Thread.sleep(forTimeInterval: 1.0)
        completion(success)
    }
    
    func startService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ()) {
        // load the file indicated by manifestURL
        guard let manifest = loadManifest(manifestURL, context) else {
            completion(false)
            return
        }
        guard let bundleID = manifest["BundleID"] as? String else {
            completion(false)
            return
        }
        guard let payloads = manifest["Payloads"] as? [String:[String:[[String:String]]]] else {
            completion(false)
            return
        }
        guard let contextFiles = payloads[context] else {
            completion(false)
            return
        }
        guard let fileList = contextFiles["Files"] else {
            completion(false)
            return
        }
        // we need the full path "/Library/LaunchDaemons/....plist
        let fullPlistName = "\(bundleID).plist"
        // let payloadFolderURL = manifestURL.deletingLastPathComponent()

        if fileList.isEmpty {
            completion(false)
            return
        }

        for fileMetadata in fileList {
            let sourceFileName = "\(fileMetadata["Filename"]!)"
            
            if sourceFileName == fullPlistName {
               let fullPathToPlist = "\(fileMetadata["Destination"]!)\(fullPlistName)"
                
                // /usr/bin/sudo /bin/launchctl bootstrap system /Library/LaunchDaemons/com.greenkitty.product.plist
                let url = URL(fileURLWithPath:"/usr/bin/sudo")
                do {
                    let args = ["/bin/launchctl", "bootstrap", "system", "\(fullPathToPlist)"]
                    try Process.run(url, arguments: args) { (process) in
                        NSLog("\nis running: \(process.isRunning)")
                        let status = process.terminationStatus
                        Thread.sleep(forTimeInterval: 1.0)
                        completion(status == 0)
                        return
                    }
                } catch {
                    NSLog("\nProcess.run failed")
                    completion(false)
                    return
                }
            }
        }
    }
    
    func cleanupFiles(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ()) {
        guard let manifest = loadManifest(manifestURL, context) else {
            completion(false)
            return
        }
        guard let payloads = manifest["Payloads"] as? [String:[String:[[String:String]]]] else {
            completion(false)
            return
        }
        guard let contextFiles = payloads[context] else {
            completion(false)
            return
        }
        guard let fileList = contextFiles["Files"] else {
            completion(false)
            return
        }

        var success = true
        
        //   for each file in manifest:
        //     if /tmp/xxx/path/to/dest/file exists:
        //       copy to /path/to/dest/file and set perms to match /tmp/xxx/path/to/dest/file
        //     end
        //   end
        for fileMetadata in fileList {
            let destFilePath = "\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!)"
            let savedFilePath = "\(restoreFolder)\(fileMetadata["Destination"]!)\(fileMetadata["Filename"]!))"
            // If the file already exists at 'dest', remove it and restore from /tmp/xxx/path/to/dest/file
            if FileManager.default.fileExists(atPath: destFilePath) {
                do {
                    try FileManager.default.removeItem(atPath: destFilePath)
                } catch {
                    success = false
                    break
                }
                // restore from savedFilePath
                do {
                    try FileManager.default.moveItem(atPath: savedFilePath, toPath: destFilePath)
                } catch {
                    success = false
                    break
                }
            }
        }

        do {
            try FileManager.default.removeItem(atPath: restoreFolder)
        } catch {
            success = false
        }
        Thread.sleep(forTimeInterval: 1.0)
        completion(success)
    }
    
    func install() {
        NSLog("\(#function)")
        client?.installationDidReachProgress(1, description: "Finished!")
    }
    
    func uninstall() {
        NSLog("\(#function)")
        
        // 1. Remove all the client files
        // 2. Kill all the processes
        // 3. Remove the Privileged Helper executable in /Library/PrivilegedHelperTools
        // 4. Remove the autogenerated plist file in /Library/LaunchDaemons
        // 5. At last, remove the Privileged Helper registration from the launchd daemon via
        // * SMJobRemove() or
        // `NSTask` (Objective-C) or `Process` (Swift) with `launchctl bootout system/com.smjobblesssample.installer`
        // from the Privileged Helper
        // To remove registration manually, use the same command in Terminal, adding `sudo` at the beginning.
        // It also kills the process.
        //
        // When debugging, check if the Helper has been unloaded successfully by running
        // `sudo launchctl list | grep com.smjobblesssample.installer`
        // in Terminal. The output should not contain th Helper label.
    }
}
