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
import Rainbow

class InitCommand: Command {
    
    let name = "init"
    
    let kind = Flag("--xcodeproj", description: "Templates for xcodeproj", defaultValue: false)
    
    func execute() throws {
        
        let templarKind: Templar.Kind
        
        if kind.value {
            let xcodeProj = try self.createXcodeTemplate()
            templarKind = .xcodeproj(xcodeProj)
        } else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "In progress".red])
//            let custom = Templar.Custom(templates: [])
//            kind = .custom(custom)
        }
        
        let templar = Templar(version: TemplarInfo.version, templateFolder: TemplarInfo.defaultFolder, kind: templarKind)
        let yamlData = try YAMLEncoder().encode(templar)
        
        stdout <<< "Create config file \(TemplarInfo.configFileName)".yellow
        try Folder.current.createFile(named: TemplarInfo.configFileName, contents: yamlData)
        stdout <<< "Create config folder \(templar.templateFolder)".yellow
        try Folder.current.createSubfolderIfNeeded(withName: templar.templateFolder)
        
        stdout <<< "Finished 🚀".green
    }
    
    // MARK: - Private
    
    private func createXcodeTemplate() throws -> Templar.XcodeProj {
        let files = Folder.current.subfolders.filter { $0.extension == "xcodeproj" }
        guard !files.isEmpty else { throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Can't found any xcodeproj files".red]) }
        
        let selectedProjectFile: Folder
        
        if files.count > 1 {
            let listOfProjects = files.enumerated().reduce("Choose your project file:\n".green, { $0.appending("\($1.offset)) \($1.element.name)") })
            let index = Input.readInt(prompt: listOfProjects, secure: false)
            selectedProjectFile = files[index]
        } else {
            let isUserProject = Input.readBool(prompt: "Is your project: \(files[0].name)? (y/n)".green, secure: false)
            
            if isUserProject {
                selectedProjectFile = files[0]
            } else {
                throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not found any project file".red])
            }
        }
        
        let project = try XcodeProj(pathString: selectedProjectFile.path)
        let targets = project.pbxproj.nativeTargets.sorted { $0.name > $1.name }
        
        let listOfTargets = targets.enumerated().reduce("Write number or numbers of targets will using for generation: \n", { $0.appending("\($1.offset)) \($1.element.name)\n") }).appending("Input use space symbol: ".green)
        let selectedIndexes = Input.readLine(prompt: listOfTargets).split(separator: " ").compactMap { Int($0) }
        
        var usingTargets: Set<String> = []
        for index in selectedIndexes {
            let targetName = targets[index].name
            usingTargets.insert(targetName)
        }
        
        let companyName = Input.readLine(prompt: "What is your company name?".green)
        
        let xcodeProj = Templar.XcodeProj(name: selectedProjectFile.name,
                                          companyName: !companyName.isEmpty ? companyName : nil ,
                                          targets: usingTargets,
                                          templates: [])
        
        return xcodeProj
    }
    
    private func createCustomTemplate() throws -> Templar.Custom {
        fatalError()
    }
    
    
}
