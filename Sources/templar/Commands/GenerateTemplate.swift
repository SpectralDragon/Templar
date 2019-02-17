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
        
        let xcFile = try Folder.current.file(named: xcodeproj.name)
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
            let templateFile = try templateFolder.file(atPath: file.name)
            var rawTemplate = try templateFile.readAsString()
         
            for item in itemsToReplace {
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
            
//            try Folder.current.subfolder(atPath: templateInfo.root).createFile(named: <#T##String#>, contents: <#T##String#>)
            
            let path = templateInfo.root + file.path
            try project.pbxproj.write(pathString: path, override: true)
        }
        
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
    
    func snakecased() -> String {
        let stringKey = self
        
        guard !stringKey.isEmpty else { return stringKey }
        
        var words : [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex
        
        // Find next uppercase character
        while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)
            
            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }
            
            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                
                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result = words.map({ (range) in
            return stringKey[range].lowercased()
        }).joined(separator: "_")
        return result
    }

}
