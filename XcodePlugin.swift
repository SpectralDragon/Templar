import TemplarPluginAPIv1

class XcodeTemplarPlugin: TemplarPlugIn {
    func generate(using rules: [TemplarPlugInLaunchingKeys : Any]) throws {
        if rules[.arguments] == "test" {
            print("hi")
        } else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "fail"])
        }
    }
}

let process = XcodeTemplarPlugin()
