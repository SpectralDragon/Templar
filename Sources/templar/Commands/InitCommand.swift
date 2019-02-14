//
//  InitCommand.swift
//  templar
//
//  Created by Vladislav Prusakov on 14/02/2019.
//

import SwiftCLI
import Foundation
import Yams
import Files
import xcodeproj

class InitCommand: Command {
    
    let name: String = "init"
    
    let type = Flag("--xcodeproj", description: "Templates for xcodeproj", defaultValue: false)
    
    func execute() throws {
        
        let kind: Templar.Kind
        
        if type.value {
            let xcodeProj = try self.createXcodeTemplate()
            kind = .xcodeproj(xcodeProj)
        } else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "In progress"])
//            let custom = Templar.Custom(templates: [])
//            kind = .custom(custom)
        }
        
        let templar = Templar(kind: kind, version: TemplarInfo.version, templateFolder: TemplarInfo.defaultFolder)
        let yamlData = try YAMLEncoder().encode(templar)
        
        try Folder.current.createFile(named: TemplarInfo.configFileName, contents: yamlData)
        try Folder.current.createSubfolderIfNeeded(withName: templar.templateFolder)
    }
    
    private func createXcodeTemplate() throws -> Templar.XcodeProj {
        let files = Folder.current.files.filter { $0.extension == "xcodeproj" }
        
        guard !files.isEmpty else { throw NSError() }
        
        let selectedProjectFile: File
        
        if files.count > 1 {
            let listOfProjects = files.enumerated().reduce("Choose your project file:\n", { $0.appending("\($1.offset)) \($1.element.name)") })
            let index = Input.readInt(prompt: listOfProjects, secure: false)
            selectedProjectFile = files[index]
        } else {
            let isUserProject = Input.readBool(prompt: "Is your project: \(files[0].name)?", secure: false)
            
            if isUserProject {
                selectedProjectFile = files[0]
            } else {
                throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not found any project file"])
            }
        }
        
        let project = try XcodeProj(pathString: selectedProjectFile.path)
        let targets = project.pbxproj.nativeTargets
        
        let listOfTargets = targets.enumerated().reduce("Write number or numbers of targets will using for generation: \n", { $0.appending("\($1.offset)) \($1.element.name)") })
        let selectedIndexes = Input.readLine(prompt: listOfTargets).split(separator: " ").compactMap { Int($0) }
        
        var usingTargets: [String] = []
        for index in selectedIndexes {
            let targetName = targets[index].name
            usingTargets.append(targetName)
        }
        
        let xcodeProj = Templar.XcodeProj(name: selectedProjectFile.nameExcludingExtension, companyName: "", targets: usingTargets, templates: [])
        
        return xcodeProj
    }
    
    
}
