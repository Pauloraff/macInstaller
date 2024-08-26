import Foundation

class XPCClient {
    
    var connection: NSXPCConnection?
    
    func start() {
        connection = NSXPCConnection(machServiceName: Constant.helperMachLabel,
                                         options: .privileged)
        
        connection?.exportedInterface = NSXPCInterface(with: InstallationClient.self)
        connection?.exportedObject = InstallationClientImpl()
        connection?.remoteObjectInterface = NSXPCInterface(with: Installer.self)
        
        connection?.invalidationHandler = connectionInvalidationHandler
        connection?.interruptionHandler = connetionInterruptionHandler
        
        connection?.resume()

        let installer = connection?.remoteObjectProxy as? Installer
        
        installer?.install()
    }
    
    private func connetionInterruptionHandler() {
        NSLog("[XPCTEST] \(type(of: self)): connection has been interrupted XPCTEST")
    }
    
    private func connectionInvalidationHandler() {
        NSLog("[XPCTEST] \(type(of: self)): connection has been invalidated XPCTEST")
    }

    func stopService(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
        let installer = connection?.remoteObjectProxy as? Installer

        installer?.stopService(manifestURL, completion: completion)
    }

    func copyNewService(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
        let installer = connection?.remoteObjectProxy as? Installer

        installer?.copyNewService(manifestURL, completion: completion)
    }
    
    func startService(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
        let installer = connection?.remoteObjectProxy as? Installer

        installer?.startService(manifestURL, completion: completion)
    }
    
    func cleanupFiles(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
        let installer = connection?.remoteObjectProxy as? Installer

        installer?.cleanupFiles(manifestURL, completion: completion)
    }
}

class InstallationClientImpl: NSObject, InstallationClient {
    func stopService(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
    }
    
    func copyNewService(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
    }
    
    func startService(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
    }
    
    func cleanupFiles(_ manifestURL: URL, completion: @escaping (Bool) -> ()) {
    }
    
    
    func installationDidReachProgress(_ progress: Double, description: String?) {
        NSLog("[XPCTEST]: \(#function)")
    }
}
