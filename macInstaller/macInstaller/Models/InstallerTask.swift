//
//  InstallerTask.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//


let InstallerTaskNames = [
    "NO MATCH",
    "STOP_SERVICE" ,
    "COPY_NEW_SERVICE",
    "START_SERVICE",
    "CLEAN_UP_FILES"
]

enum InstallerTaskState: Int {
    case pending = 1
    case running = 2
    case completed = 3
    case failed = 4
    case skipped = 5
}

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

struct InstallerTaskModel: Identifiable {
    let task: InstallerTask
    let state: InstallerTaskState
    
    var id: Int { task.rawValue << 4 | state.rawValue  }
}

