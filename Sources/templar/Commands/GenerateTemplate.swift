//
//  GenerateTemplate.swift
//  templar
//
//  Created by Vladislav Prusakov on 14/02/2019.
//

import SwiftCLI
import Foundation
import Yams
import Files
import xcodeproj

class GenerateTemplate: Command {
    
    let name: String = "generate"
    
    let templateName = Parameter()
    
    private var decoder = YAMLDecoder()
    
    func execute() throws {
        guard let file = try? Folder.current.file(named: TemplarInfo.configFileName) else { throw TemplarError.configNotFound }
        
        let templar = try decoder.decode(Templar.self, from: try file.readAsString())
        
        switch templar.kind {
        case .xcodeproj(let xcodeproj):
            try self.generateTemplateForXcodeProj(xcodeproj, templar: templar)
        case .custom(let custom):
            print("")
        }
    }
    
    func generateTemplateForXcodeProj(_ xcodeproj: Templar.XcodeProj, templar: Templar) throws {
        
        guard let selectedTemplate = xcodeproj.targets.first(where: { $0 == templateName.value }) else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: ""])
        }
        
        let templatesFolder = try Folder.current.subfolder(named: templar.templateFolder)
        let file = try templatesFolder.file(named: selectedTemplate)
        
        let templateInfo = try decoder.decode(Template.self, from: try file.readAsString())
        
        let xcFile = try Folder.current.file(named: xcodeproj.name)
        let project = try XcodeProj(pathString: xcFile.path)
        
        guard !templateInfo.root.isEmpty else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Path to root in template \(templateName.value) is empty"])
        }
        
        for item in templateInfo.items {
            let templateFile = try templatesFolder.file(atPath: item.pathToTemplate)
            var templateData = try templateFile.readAsString()
            // TODO: Generation
        }
        
    }
    
}

struct Template: Codable {
    
    struct Item: Codable {
        let pathToTemplate: String
        let replaceRules: [String: String]
    }
    
    let root: String
    let items: [Item]
}



enum TemplarError: LocalizedError {
    
    case configNotFound
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Templar config not found. Using \"templar init\" to initialize config"
        }
    }
    
}
