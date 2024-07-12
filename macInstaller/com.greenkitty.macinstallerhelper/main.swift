//
//  main.swift
//  InstallerHelper
//
//  Created by Paulo Raffaelli on 7/7/24.
//

import Foundation

NSLog("mac Installer helper has started")

XPCServer.shared.start()

CFRunLoopRun()

