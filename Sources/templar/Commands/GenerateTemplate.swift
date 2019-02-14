//
//  GenerateTemplate.swift
//  templar
//
//  Created by v.a.prusakov on 14/02/2019.
//

import SwiftCLI
import Foundation
import Yams
import Files

class GenerateTemplate: Command {
    
    let name: String = "generate"
    
//    let action = Act
    
    func execute() throws {
        guard let file = try? Folder.current.file(named: TemplarInfo.configFileName) else { throw TemplarError.configNotFound }
        
        let templar = try YAMLDecoder().decode(Templar.self, from: try file.readAsString())
        
        switch templar.kind {
        case .xcodeproj(let xcodeproj):
            print("")
        case .custom(let custom):
            print("")
        }
        
        let sdkPathProcess = Process.launchedProcess(launchPath: "/usr/bin/", arguments: ["xcrun", "--sdk", "macosx", "--show-sdk-path"])
        sdkPathProcess.launch()
        
        var command: [String] = []
        command += ["swiftc"]
        command += ["--driver-mode=swift"]
        command += []
        let process = Process.launchedProcess(launchPath: "/usr/bin/", arguments: command)
        process.launch()
        
    }
    
}

public enum TemplarError: LocalizedError {
    
    case configNotFound
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Templar config not found. Using \"templar init\" to initialize config"
        }
    }
    
}

