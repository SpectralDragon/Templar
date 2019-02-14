//
//  TemplarTool.swift
//  templar
//
//  Created by Vladislav Prusakov on 14/02/2019.
//

import Foundation
import SwiftCLI

class TemplarTool {
    
    private let commandLineTool: CLI
    private let arguments: [String]
    
    init(arguments: [String]) {
        self.commandLineTool = CLI(name: TemplarInfo.name, version: TemplarInfo.version, description: "Templar - generate your templates", commands: [InitCommand(), GenerateTemplate()])
        self.arguments = arguments
    }
    
    func run() {
        let result = commandLineTool.go(with: arguments)
        exit(result)
    }
}
