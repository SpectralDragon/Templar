//
//  Templar.swift
//  templar
//
//  Created by Vladislav Prusakov on 14/02/2019.
//

import Foundation

struct Templar: Codable {
    
    struct XcodeProj: Codable {
        let name: String
        let companyName: String?
        var targets: Set<String>
        var templates: Set<String>
    }
    
    struct Custom: Codable {
        let companyName: String?
        var templates: Set<String>
    }
    
    enum Kind: Codable {
        case xcodeproj(XcodeProj)
        case custom(Custom)
    }
    
    var version: String
    let templateFolder: String
    var kind: Kind
}

extension Templar.Kind {
    
    private enum Keys: CodingKey {
        case xcodeproj, custom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        if let xcodeproj = try container.decodeIfPresent(Templar.XcodeProj.self, forKey: .xcodeproj) {
            self = .xcodeproj(xcodeproj)
            return
        }
        
        if let custom = try container.decodeIfPresent(Templar.Custom.self, forKey: .custom) {
            self = .custom(custom)
            return
        }
        
        throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Can't parse templar config"])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case .xcodeproj(let xcodeproj):
            try container.encode(xcodeproj, forKey: .xcodeproj)
        case .custom(let custom):
            try container.encode(custom, forKey: .custom)
        }
    }
}
