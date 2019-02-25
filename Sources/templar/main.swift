import Foundation

enum TemplarInfo {
    static let name = "templar"
    static let version = "1.0.0"
    static let defaultFolder = ".templates"
    static let configFileName = ".templar"
    static let templateFileExtension = "templar"
}


let tool = TemplarTool(arguments: Array(CommandLine.arguments.dropFirst()))
tool.run()
