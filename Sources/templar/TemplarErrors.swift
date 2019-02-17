//
//  TemplarErrors.swift
//  templar
//
//  Created by Vladislav Prusakov on 18/02/2019.
//

import Foundation

enum TemplarError: LocalizedError {
    
    case configNotFound
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Templar config not found. Using \"templar init\" to initialize config"
        }
    }
}
