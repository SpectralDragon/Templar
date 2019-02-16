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
    
    let name = "generate"
    
    let templateName = Parameter()
    
    private var decoder = YAMLDecoder()
    
    func execute() throws {
        guard let file = try? Folder.current.file(named: TemplarInfo.configFileName) else { throw TemplarError.configNotFound }
        
        let templar = try decoder.decode(Templar.self, from: try file.readAsString())
        
        switch templar.kind {
        case .xcodeproj(let xcodeproj):
            try self.generateTemplateForXcodeProj(xcodeproj, templar: templar)
        case .custom(let custom):
            print(custom)
        }
    }
    
    // MARK: - Private
    
    private func generateTemplateForXcodeProj(_ xcodeproj: Templar.XcodeProj, templar: Templar) throws {
        
        guard let selectedTemplate = xcodeproj.templates.first(where: { $0 == templateName.value }) else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Template not found by name \(templateName.value) in config".red])
        }
        
        let templateFolder = try Folder.current.subfolder(named: templar.templateFolder).subfolder(named: selectedTemplate)
        let file = try templateFolder.file(named: Template.makeFullName(from: selectedTemplate))
        
        let templateInfo = try decoder.decode(Template.self, from: try file.readAsString())
        
//        let xcFile = try Folder.current.file(named: xcodeproj.name)
//        let project = try XcodeProj(pathString: xcFile.path)
        
        guard !templateInfo.root.isEmpty else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Path to root in template \(templateName.value) is empty".red])
        }
        
//        let answers = templateInfo.replaceRules.map {
//            return Input.readLineWhileNotGetAnswer(prompt: $0.question, error: "Answer can't be empty", output: stderr)
//        }
//        
        let pattern = templateInfo.replaceRules.reduce("", { "\($0)|\($1.pattern)"})
        
        for file in templateInfo.files {
            let templateFile = try templateFolder.file(atPath: file.path)
            let rawTemplate = try templateFile.readAsString()
            
            
            
            let exp = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = exp.matches(in: rawTemplate, options: [], range: NSRange(0...rawTemplate.count))
            
            print(matches)
//            let templateFile = try templatesFolder.file(atPath: file.pathToTemplate)
//            var templateData = try templateFile.readAsString()
//            templateData
            
            // TODO: Generation
            
//            try project.pbxproj.write(pathString: file.pathToTemplate, override: true)
        }
        
    }
}

extension Array where Element == Template.Modifier {
    var string: String {
        return self.reduce("", { "\($0)|\($1.rawValue)"})
    }
}

struct Template: Codable {
    
    enum Modifier: String, CaseIterable {
        case lowercase
        case lowerCamelCase
        case uppercase
        case upperCamelCase
        case snake_case
    }
    
    struct File: Codable {
        let name: String
        let path: String
    }
    
    struct Rule: Codable {
        let pattern: String
        let question: String
    }
    
    let version: String
    
    let summary: String?
    let author: String?
    
    let root: String
    let files: [File]
    
    let replaceRules: [Rule]
    
    static func makeFullName(from name: String) -> String {
        return "\(name).\(TemplarInfo.templateFileExtension)"
    }
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
