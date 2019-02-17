//
//  Template.swift
//  templar
//
//  Created by Vladislav Prusakov on 17/02/2019.
//

import Foundation

struct Template: Codable {
    
    enum Modifier: String, CaseIterable {
        case lowercase
        case firstLowercased
        case uppercase
        case firstUppercased
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
