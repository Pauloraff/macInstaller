//
//  InstallScope.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//


enum InstallScope: String, Identifiable, Hashable {
    case allUsers = "AllUsers"
    case user = "User"
    
    var id: Int { rawValue.hash  }
}

