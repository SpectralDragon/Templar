import SwiftCLI
import Foundation
import Yams
import Files

enum TemplarInfo {
    static let name = "templar"
    static let version = "1.0.0"
    static let defaultFolder = ".templates"
    static let templateFileName = ".templar"
}

struct Templar: Codable {
    
    struct XcodeProj: Codable {
        let name: String
        let companyName: String
    }
    
    struct Custom: Codable {
        
    }
    
    enum Kind: Codable {
        case xcodeproj(XcodeProj)
        case custom
    }
    
    let type: Kind
    let version: String
    let templateFolder: String
}

extension Templar.Kind {
    
    private enum Keys: CodingKey {
        case xcodeproj, custom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        if let xcodeproj = try container.decodeIfPresent(Templar.XcodeProj.self, forKey: .xcodeproj) {
            self = .xcodeproj(xcodeproj)
            return
        }
        
        self = .custom
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case .xcodeproj(let xcodeproj):
            try container.encode(xcodeproj, forKey: .xcodeproj)
        case .custom:
            try container.encode("custom", forKey: .custom)
        }
    }
}

class InitCommand: Command {
    let name: String = "init"
    
    let type = Flag("--xcodeproj", description: "Templates for xcodeproj", defaultValue: false)
    
    func execute() throws {
        
        let kind: Templar.Kind
        
        if type.value {
            
            let files = Folder.current.files.filter { $0.extension == "xcodeproj" }
            
            guard !files.isEmpty else { throw NSError() }
            
            let projectName: String
            
            if files.count > 1 {
                let listOfProjects = files.enumerated().reduce("", { $0.appending("\($1.offset)) \($1.element.name)") })
                let index = Input.readInt(prompt: "Choose your project file:\n\(listOfProjects)", secure: false)
                projectName = files[index].nameExcludingExtension
            } else {
                let isUserProject = Input.readBool(prompt: "Is your project: \(files[0].name)?", secure: false)
                
                if isUserProject {
                    projectName = files[0].nameExcludingExtension
                } else {
                    throw NSError()
                }
            }
            
            let xcodeProj = Templar.XcodeProj(name: projectName, companyName: "")
            kind = .xcodeproj(xcodeProj)
        } else {
           kind = .custom
        }
        
        let templar = Templar(type: kind, version: TemplarInfo.version, templateFolder: TemplarInfo.defaultFolder)
        let yamlData = try YAMLEncoder().encode(templar)
        
        try Folder.current.createFile(named: TemplarInfo.templateFileName, contents: yamlData)
        try Folder.current.createSubfolderIfNeeded(withName: templar.templateFolder)
    }
}

class GenerateTemplate: Command {
    
    let name: String = "generate"
    
    func execute() throws {
        
    }
    
}

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


let tool = TemplarTool(arguments: CommandLine.arguments)
tool.run()
