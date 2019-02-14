//
//  Templar.swift
//  templar
//
//  Created by v.a.prusakov on 14/02/2019.
//

import Foundation

public struct Templar: Codable {
    
    public struct XcodeProj: Codable {
        public let name: String
        public let companyName: String
        public var templates: [String]
    }
    
    public struct Custom: Codable {
        
        public var templates: [String]
    }
    
    public enum Kind: Codable {
        /// Generate files and folders to xcodeproj
        case xcodeproj(XcodeProj)
        
        /// Support custom template files
        case custom(Custom)
    }
    
    /// Kind of
    public let kind: Kind
    
    /// Version of templar config
    public var version: String
    
    /// Default folder path to templates.
    public let templateFolderPath: String
}

public extension Templar.Kind {
    
    private enum Keys: CodingKey {
        case xcodeproj, custom
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        if let xcodeproj = try container.decodeIfPresent(Templar.XcodeProj.self, forKey: .xcodeproj) {
            self = .xcodeproj(xcodeproj)
            return
        }
        
        if let custom = try container.decodeIfPresent(Templar.Custom.self, forKey: .custom) {
            self = .custom(custom)
        }
        
        throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Couldn't parse templar kind."])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        switch self {
        case .xcodeproj(let xcodeproj):
            try container.encode(xcodeproj, forKey: .xcodeproj)
        case .custom(let custom):
            try container.encode(custom, forKey: .custom)
        }
    }
}

public extension Templar {
    public struct Template: Codable {
        public let name: String
        public let path: String
    }
}

public extension Templar {
    public struct Plugin: Codable {
        public let action: String
        public let path: String
    }
}
