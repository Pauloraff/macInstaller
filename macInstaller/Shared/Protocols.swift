import Foundation

@objc protocol Installer {
    func install()
    func uninstall()
    func stopService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
    func copyNewService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
    func startService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
    func cleanupFiles(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
}

@objc public protocol InstallationClient {
    func installationDidReachProgress(_ progress: Double, description: String?)
    
    func stopService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())

    func copyNewService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
    
    func startService(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
    
    func cleanupFiles(_ manifestURL: URL, _ context: String, completion: @escaping (Bool) -> ())
}
