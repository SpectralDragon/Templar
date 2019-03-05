//
// Created by admin on 2019-03-06.
//

import PathKit
import Foundation


enum DefaultPlaceholder: String, CaseIterable {

    case year = "__YEAR__"
    case author = "__AUTHOR__"
    case date = "__DATE__"
    case companyName = "__COMPANY_NAME__"
    case file = "__FILE__"
    case project = "__PROJECT__"
    case name = "__NAME__"


    func valueToReplace(using templar: Templar, template: Template, fullPath: Path, moduleName: String) -> String? {
        switch self {
        case .author:
            return template.author
        case .date:
            let formatter = DateFormatter()
            formatter.dateFormat = template.settings?.dateFormat ?? "dd/MM/YYYY"
            return formatter.string(from: Date())
        case .companyName:
            switch templar.kind {
            case .xcodeproj(let xcodeproj):
                return xcodeproj.companyName
            case .custom(let custom):
                return custom.companyName
            }
        case .file:
            return fullPath.lastComponent
        case .project:
            switch templar.kind {
            case .xcodeproj(let xcodeproj):
                return template.settings?.projectName ?? Path(xcodeproj.name).lastComponentWithoutExtension
            case .custom:
                return nil
            }
        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY"
            return formatter.string(from: Date())
        case .name:
            return moduleName
        }
    }
}