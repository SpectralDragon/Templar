//
// Created by admin on 2019-03-06.
//

import Foundation


extension String {

    func firstLowercased() -> String {
        guard let first = first else { return self }
        return String(first).lowercased() + dropFirst()
    }

    func firstUppercased() -> String {
        guard let first = first else { return self }
        return String(first).capitalized + dropFirst()
    }

    /// - seealso: https://gist.github.com/ivanbruel/e72d938f49db64d2f5df09fb9420c1e2
    func snakecased() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let replacingResult = regex?.stringByReplacingMatches(in: self,
                                                              options: [],
                                                              range: NSRange(0..<self.count),
                                                              withTemplate: "$1_$2")

        return replacingResult?.lowercased() ?? self
    }

    /// Regex pattern looks like YOURPATTERN(=lowercased=|=snake_case=|)
    mutating func replace(pattern: String, with value: String) throws {

        let allModifiers = Template.Modifier.allCases

        let expression = try NSRegularExpression(pattern: "\(pattern)(\(allModifiers.pattern))",
                                                 options: .caseInsensitive)

        let matchResult = expression.firstMatch(in: self, options: [], range: NSRange(0..<self.count))

        while let matchRange = matchResult.flatMap({ Range($0.range, in: self) }) {
            let currentMatchString = String(self[matchRange])
            var textToReplace = value

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
            self.replaceSubrange(matchRange, with: textToReplace)
        }
    }

}