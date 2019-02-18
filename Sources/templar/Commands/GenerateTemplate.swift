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
import PathKit

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
        
        let xcFile = try Folder.current.subfolder(named: xcodeproj.name)
        let project = try XcodeProj(pathString: xcFile.path)
        
        guard !templateInfo.root.isEmpty else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Path to root in template \(templateName.value) is empty".red])
        }
        
        let itemsToReplace = templateInfo.replaceRules.map { rule -> (answer: String, pattern: String) in
            let answer = Input.readLineWhileNotGetAnswer(prompt: rule.question, error: "Answer can't be empty", output: stderr)
            return (answer, rule.pattern)
        }
        
        let allModifiers = Template.Modifier.allCases
        
        for file in templateInfo.files {
            let templateFile = try templateFolder.file(atPath: file.templatePath)
            var rawTemplate = try templateFile.readAsString()
         
            for item in itemsToReplace {
                // Regex pattern looks like YOURPATTERN(=lowercased|=snake_case|)
                let expression = try NSRegularExpression(pattern: "\(item.pattern)(\(allModifiers.pattern))", options: .caseInsensitive)
                
                while let range = expression.firstMatch(in: rawTemplate, options: [], range: NSRange(0..<rawTemplate.count)).flatMap( { Range($0.range, in: rawTemplate) }) {
                    let currentMatchString = String(rawTemplate[range])
                    var textToReplace = item.answer
                    
                    if let modifier = allModifiers.first(where: { currentMatchString.hasSuffix($0.rawValue) }) {
                        switch modifier {
                        case .lowercase:
                            textToReplace = textToReplace.lowercased()
                        case .firstLowercased:
                            textToReplace = textToReplace.firstLowercased()
                        case .uppercase:
                            textToReplace = textToReplace.uppercased()
                        case .firstUppercased:
                            textToReplace = textToReplace.firstUppercased()
                        case .snake_case:
                            textToReplace = textToReplace.snakecased()
                        }
                    }
                    
                    rawTemplate.replaceSubrange(range, with: textToReplace)
                }
            }
            
            let filePath = Path(file.path)
            let rootPath = Path(templateInfo.root)
            let path = rootPath + filePath
            let fullPath = Path(Folder.current.path) + path
            
            try fullPath.parent().mkpath()
            try fullPath.write(rawTemplate)

            if let rootGroup = project.pbxproj.groups.first(where: { templateInfo.root.hasPrefix($0.path ?? "") == true }) {
                print(rootGroup.path as Any)
                
                let pathToAddedGroup = Path(String(templateInfo.root.dropFirst(rootGroup.path.orEmpty.count))) + filePath.parent()
                
                
                let createdGroups = try rootGroup.addGroup(named: pathToAddedGroup.string)
                
                print(createdGroups)
                if createdGroups.isEmpty {
                    stderr <<< "Can't get groups by path \(Path(file.path).string) for root group \(rootGroup.path ?? "")".red
                    continue
                }
                createdGroups.forEach {
                    print($0.path as Any)
                }
                try createdGroups.last?.addFile(at: fullPath, sourceRoot: Path(xcFile.path))
            } else {
                stderr <<< "Can't found root group in xcodeproject by path \(templateInfo.root)".red
                continue
            }
            
            
        }
        
        try project.write(pathString: xcFile.path, override: true)
        
        stdout <<< "Did finish generate 🛠".green
    }
}

fileprivate extension Array where Element == Template.Modifier {
    var pattern: String {
        return self.reduce("", { "\($0)=\($1.rawValue)|"})
    }
}

fileprivate extension String {
    
    func firstLowercased() -> String {
        guard let first = first else { return self }
        return String(first).lowercased() + dropFirst()
    }
    
    func firstUppercased() -> String {
        guard let first = first else { return self }
        return String(first).capitalized + dropFirst()
    }
    
    /// - seealso: https://gist.github.com/ivanbruel/e72d938f49db64d2f5df09fb9420c1e2
    func snakecased() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let replacingResult = regex?.stringByReplacingMatches(in: self, options: [],
                                               range: NSRange(0..<self.count), withTemplate: "$1_$2")
        
        return replacingResult?.lowercased() ?? self
    }

}
