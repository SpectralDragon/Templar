//
//  Template.swift
//  templar
//
//  Created by Vladislav Prusakov on 17/02/2019.
//

import Foundation

struct Template: Codable {
    
    let version: String
    
    let summary: String?
    let author: String?
    
    let settings: Settings?
    
    let root: String
    let files: [File]
    
    let replaceRules: [Rule]?
    
    let scripts: [String]?
    
}

extension Template {
    
    struct Settings: Codable {
        let dateFormat: String?
        let projectName: String?
        let licensePath: String?
    }
    
    enum Modifier: String, CaseIterable {
        case lowercase
        case firstLowercased
        case uppercase
        case firstUppercased
        case snake_case
    }
    
    struct File: Codable {
        let path: String
        let templatePath: String
    }
    
    struct Rule: Codable {
        let pattern: String
        let question: String
    }
}

extension Template {
    static func makeFullName(from name: String) -> String {
        return "\(name).\(TemplarInfo.templateFileExtension)"
    }
}

extension Array where Element == Template.Modifier {
    var pattern: String {
        return self.reduce("", { "\($0)=\($1.rawValue)=|"})
    }
}