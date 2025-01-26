//
//  InstallerStep.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//

enum InstallerStep: Int, CaseIterable {
    case introduction
    case license
    case awaitingLicenseAcceptance // this is hidden in the UI, and corresponds to a modal dialog.
    
    // put your custom installer steps below this line

    // User credentials, login, etc. etc.

    // put your custom installer steps above this line

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
            case .awaitingLicenseAcceptance: // hidden in the UI
                return "ACCEPT_LICENSE"      // never visible in the UI
                
            // put your custom installer step labels below this line
            
            // User credentials, login, etc. etc.
                
            // put your custom installer step labels above this line

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
