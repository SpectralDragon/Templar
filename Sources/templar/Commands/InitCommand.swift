//
//  InitCommand.swift
//  templar
//
//  Created by v.a.prusakov on 14/02/2019.
//

import SwiftCLI
import Foundation
import Yams
import Files
import TemplarCore

final class InitCommand: Command {
    
    let name: String = "init"
    
    let type = Flag("--xcodeproj", description: "Templates for xcodeproj", defaultValue: false)
    
    func execute() throws {
        
        if Folder.current.containsFile(named: TemplarInfo.configFileName) {
            let needsRemoveAllData = Input.readBool(prompt: "Templar config is exists. Do you wanna remove a templar config and install the new?")
            
            if needsRemoveAllData {
                let file = try Folder.current.file(named: TemplarInfo.configFileName)
                try file.delete()
            } else {
                throw NSError(domain: "templar", code: 0, userInfo: [NSLocalizedDescriptionKey: "It was a mistake, because init command couldn't be used when the templar config is exists."])
            }
        }
        
        let kind: Templar.Kind
        
        if type.value {
            
            let files = Folder.current.files.filter { $0.extension == "xcodeproj" }
            
            guard !files.isEmpty else { throw NSError.init(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not found any project files"]) }
            
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
                    throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not found user project file"])
                }
            }
            
            let xcodeProj = Templar.XcodeProj(name: projectName, companyName: "", templates: [])
            kind = .xcodeproj(xcodeProj)
        } else {
            let custom = Templar.Custom(templates: [""])
            kind = .custom(custom)
        }
        
        let templar = Templar(kind: kind, version: TemplarInfo.version, templateFolderPath: TemplarInfo.defaultFolder)
        let yamlData = try YAMLEncoder().encode(templar)
        
        try Folder.current.createFile(named: TemplarInfo.configFileName, contents: yamlData)
        try Folder.current.createSubfolderIfNeeded(withName: templar.templateFolderPath)
    }
}
