//
//  Extensions.swift
//  templar
//
//  Created by Vladislav Prusakov on 18/02/2019.
//

import Foundation
import SwiftCLI
import Rainbow

extension Input {
    static func readLineWhileNotGetAnswer(prompt: String, error: String, output: WritableStream) -> String {
        let answer = Input.readLine(prompt: prompt.green)
        
        guard !answer.isEmpty else {
            output <<< error.red
            return readLineWhileNotGetAnswer(prompt: prompt, error: error, output: output)
        }
        
        return answer
    }
}

extension String {
    static var empty = String()
}

extension Optional where Wrapped == String {
    var orEmpty: String {
        return self ?? ""
    }
}
