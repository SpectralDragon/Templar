import Foundation

public enum TemplarPlugInLaunchingKeys {
    /// Return dictionary of arguments `[String: Any]`
    case arguments
    
    /// Return selected template `Templar.Template`
    case template
}

public protocol TemplarPlugIn {
    func generate(using rules: [TemplarPlugInLaunchingKeys: Any]) throws
}
