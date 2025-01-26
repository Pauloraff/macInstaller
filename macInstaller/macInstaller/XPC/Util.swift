import SecurityFoundation
import ServiceManagement

struct Util {
    static func askAuthorization() -> AuthorizationRef? {
        var auth: AuthorizationRef?
        let status: OSStatus = AuthorizationCreate(nil, nil, [], &auth)
        if status != errAuthorizationSuccess {
            NSLog("Authorization failed with status code \(status)")
            
            return nil
        }
        
        return auth
    }
    
    @discardableResult
    static func blessHelper(label: String, authorization: AuthorizationRef) -> Bool {
        var error: Unmanaged<CFError>?
        let blessStatus = SMJobBless(kSMDomainSystemLaunchd, label as CFString, authorization, &error)
        
        if !blessStatus {
            NSLog("Helper bless failed with error \(error!.takeUnretainedValue())")
        }
        
        return blessStatus
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
