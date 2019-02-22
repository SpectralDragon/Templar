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
            try generateTemplate(for: xcodeproj, using: templar)
        case .custom(let custom):
            try generateTemplate(for: custom, using: templar)
        }
    }
    
    // MARK: - Private
    
    private func generateTemplate(for xcodeproj: Templar.XcodeProj, using templar: Templar) throws {
        
        guard let selectedTemplate = xcodeproj.templates.first(where: { $0 == templateName.value }) else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Template not found by name \(templateName.value) in config".red])
        }
        
        let xcFile = try Folder.current.subfolder(named: xcodeproj.name)
        let project = try XcodeProj(pathString: xcFile.path)
        
        try generateFiles(using: templar, selectedTemplate: selectedTemplate) { template, file, path in
            let findedGroup = project.pbxproj.groups.first(where: {
                if let path = $0.path, !path.isEmpty {
                    return template.root.hasPrefix(path)
                } else {
                    return false
                }
            })
            
            if let rootGroup = findedGroup {
                let pathToAddedGroup = Path(String(path.string.dropFirst(rootGroup.path.orEmpty.count)))
                
                let createdGroups = try rootGroup.addGroup(named: pathToAddedGroup.parent().string)
                
                if createdGroups.isEmpty {
                    self.stderr <<< "Can't get groups by path \(Path(file.path).string) for root group \(rootGroup.path ?? "")".red
                    return
                }
                
                if let lastGroupInChain = createdGroups.last {
                    let file = PBXFileElement(sourceTree: .group, path: nil, name: path.lastComponent, includeInIndex: true)
                    let buildFile = PBXBuildFile(file: file)
                    project.pbxproj.add(object: buildFile)
                    try lastGroupInChain.addFile(at: path, sourceTree: .group, sourceRoot: Path(xcFile.path).parent())
                } else {
                    throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create file by path \(path.string)".red])
                }
            } else {
                self.stderr <<< "Can't found root group in xcodeproject by path \(template.root)".red
                return
            }
            
            try project.write(pathString: xcFile.path, override: true)
        }
    }
    
    private func generateTemplate(for custom: Templar.Custom, using templar: Templar) throws {
        
        guard let selectedTemplate = custom.templates.first(where: { $0 == templateName.value }) else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Template not found by name \(templateName.value) in config".red])
        }
        
        try generateFiles(using: templar, selectedTemplate: selectedTemplate) { _, _, _ in
            
        }
        
    }
    
    private func generateFiles(using templar: Templar,
                               selectedTemplate: String,
                               onGenerateFileFinishHandler: @escaping (_ template: Template, _ file: Template.File, _ path: Path) throws -> Void) throws {
        
        let templateFolder = try Folder.current.subfolder(named: templar.templateFolder).subfolder(named: selectedTemplate)
        let file = try templateFolder.file(named: Template.makeFullName(from: selectedTemplate))
        let template = try decoder.decode(Template.self, from: try file.readAsString())
        
        guard !template.root.isEmpty else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Path to root in template \(templateName.value) is empty".red])
        }
        
        let itemsToReplace = template.replaceRules.map { rule -> (answer: String, pattern: String) in
            let answer = Input.readLineWhileNotGetAnswer(prompt: rule.question, error: "Answer can't be empty", output: stderr)
            return (answer, rule.pattern)
        }
        
        let allModifiers = Template.Modifier.allCases
        
        for file in template.files {
            let templateFile = try templateFolder.file(atPath: file.templatePath)
            guard templateFile.extension == "templar" else {
                stderr <<< "Skipping template file \(templateFile.name). Templar support only template file with \".templar\" extension ".red
                continue
            }
            var rawTemplate = try templateFile.readAsString()
            
            for item in itemsToReplace {
                // Regex pattern looks like YOURPATTERN(=lowercased=|=snake_case=|)
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
            let rootPath = Path(template.root)
            let path = rootPath + filePath
            let fullPath = Path(Folder.current.path) + path
            
            try fullPath.parent().mkpath()
            try fullPath.write(rawTemplate)
            
            try onGenerateFileFinishHandler(template, file, path)
        }
        
        if let scripts = template.scripts, !scripts.isEmpty {
            stdout <<< "Begin executing scripts".yellow
            
            for script in scripts {
                let arguments = script.split(separator: " ").map(String.init)
//                let process = Process.launchedProcess(launchPath: "/usr/bin", arguments: arguments)
//                
//                if #available(macOS 10.13, *) {
//                    try process.run()
//                } else {
//                    process.launch()
//                }
                
            }
            
            stdout <<< "Did finish executing scripts".yellow
        }
        
        stdout <<< "Did finish generate 🛠".green.bold
    }
}

fileprivate extension Array where Element == Template.Modifier {
    var pattern: String {
        return self.reduce("", { "\($0)=\($1.rawValue)=|"})
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
