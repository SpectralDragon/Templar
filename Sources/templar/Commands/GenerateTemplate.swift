//
//  GenerateTemplate.swift
//  templar
//
//  Created by Vladislav Prusakov on 14/02/2019.
//

import SwiftCLI
import Foundation
import Yams
import Files
import xcodeproj
import PathKit

class GenerateTemplate: Command {

    let name = "generate"

    let templateName = Parameter()

    let moduleName = Parameter()

    private var decoder = YAMLDecoder()

    func execute() throws {
        guard let file = try? Folder.current.file(named: TemplarInfo.configFileName) else { throw TemplarError.configNotFound }

        let templar = try decoder.decode(Templar.self, from: try file.readAsString())

        switch templar.kind {
        case .xcodeproj(let xcodeproj):
            try generateTemplate(for: xcodeproj, using: templar)
        case .custom(let custom):
            try generateTemplate(for: custom, using: templar)
        }
    }

    // MARK: - Private

    private func generateTemplate(for xcodeproj: Templar.XcodeProj, using templar: Templar) throws {

        guard let selectedTemplate = xcodeproj.templates.first(where: { $0 == templateName.value }) else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Template not found by name \(templateName.value) in config".red])
        }

        let xcFile = try Folder.current.subfolder(named: xcodeproj.name)
        let project = try XcodeProj(pathString: xcFile.path)


        let targets = project.pbxproj.nativeTargets.filter { target -> Bool in
            return xcodeproj.targets.contains(target.name)
        }

        try generateFiles(using: templar, selectedTemplate: selectedTemplate) { template, file, fullPath in
            let findedGroup = project.pbxproj.groups.first(where: {
                if let path = $0.path, !path.isEmpty {
                    return fullPath.string.hasPrefix(path)
                } else {
                    return false
                }
            })

            if let rootGroup = findedGroup {

                var stringPathToAddedGroup = String(fullPath.string.dropFirst(rootGroup.path.orEmpty.count))

                // Remove first slash, because xcodeproj will generate empty group
                if stringPathToAddedGroup.first == "/" {
                    stringPathToAddedGroup.removeFirst()
                }
                let pathToAddedGroup = Path(stringPathToAddedGroup)

                let createdGroups = try rootGroup.addGroupOrUseExists(named: pathToAddedGroup.parent().string)

                if createdGroups.isEmpty {
                    self.stderr <<< "Can't get groups by path \(Path(file.path).string) for root group \(rootGroup.path ?? "")".red
                    return
                }

                if let lastGroupInChain = createdGroups.last {
                    let fileReference = PBXFileReference(sourceTree: .group, name: fullPath.lastComponent,
                                     explicitFileType: fullPath.extension.flatMap(Xcode.filetype),
                                     lastKnownFileType: fullPath.extension.flatMap(Xcode.filetype),
                                     path: fullPath.lastComponent)

                    if let index = lastGroupInChain.children.index(where: { $0.name == fileReference.name }) {
                        let oldFileRef = lastGroupInChain.children[index]
                        lastGroupInChain.children[index] = fileReference
                        project.pbxproj.delete(object: oldFileRef)

                    } else {
                        lastGroupInChain.children.append(fileReference)
                    }

                    project.pbxproj.add(object: fileReference)

                    for target in targets {
                        let buildPhase = try target.sourcesBuildPhase()
                        try buildPhase?.updateOrAdd(file: fileReference) // I don't know why this method isn't @discardableResult
                    }

                } else {
                    throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create file by path \(fullPath.string)".red])
                }
            } else {
                self.stderr <<< "Can't found root group in xcodeproject by path \(template.root)".red
                return
            }

            try project.write(pathString: xcFile.path, override: true)
        }
    }

    private func generateTemplate(for custom: Templar.Custom, using templar: Templar) throws {

        guard let selectedTemplate = custom.templates.first(where: { $0 == templateName.value }) else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Template not found by name \(templateName.value) in config".red])
        }

        try generateFiles(using: templar, selectedTemplate: selectedTemplate) { _, _, _ in
            /// Custom template not need
        }

    }

    /// Generate file and return file path to generated file
    /// - parameter templar: Templar config.
    /// - parameter selectedTemplate: Selected template name use for generating.
    /// - parameter onGenerateFileFinishHandler: Return selected template, template file and full path to generated file. Call after template file was generate succefly.
    private func generateFiles(using templar: Templar,
                               selectedTemplate: String,
                               onGenerateFileFinishHandler: @escaping (_ template: Template, _ file: Template.File, _ path: Path) throws -> Void) throws {

        let templateFolder = try Folder.current.subfolder(named: templar.templateFolder).subfolder(named: selectedTemplate)
        let file = try templateFolder.file(named: Template.makeFullName(from: selectedTemplate))
        let template = try decoder.decode(Template.self, from: try file.readAsString())

        guard !template.root.isEmpty else {
            throw NSError(domain: "templar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Path to root in template \(templateName.value) is empty".red])
        }

        let itemsToReplace = template.replaceRules?.compactMap { rule -> (answer: String, pattern: String) in
            let answer = Input.readLineWhileNotGetAnswer(prompt: rule.question, error: "Answer can't be empty", output: stderr)
            return (answer, rule.pattern)
        }

        for file in template.files {
            let templateFile = try templateFolder.file(atPath: file.templatePath)
            guard templateFile.extension == "templar" else {
                stderr <<< "Skipping template file \(templateFile.name). Templar support only template file with \".templar\" extension ".red
                continue
            }
            var rawTemplate = try templateFile.readAsString()

            for item in itemsToReplace ?? [] {
                try rawTemplate.replace(pattern: item.pattern, with: item.answer)
            }

            // We must insert moduleName before
            var filePath = Path(file.path)
            let finishFileName = Path(moduleName.value.appending(filePath.lastComponent))
            filePath = Path(String(filePath.string.dropLast(filePath.lastComponent.count))) + finishFileName

            for key in DefaultPlaceholder.allCases {
                if let value = key.valueToReplace(using: templar, template: template, fullPath: filePath, moduleName: moduleName.value) {
                    try rawTemplate.replace(pattern: key.rawValue, with: value)
                }
            }

            let rootPath = Path(template.root) + Path(moduleName.value)
            let path = rootPath + filePath
            let fullPath = Path(Folder.current.path) + path

            try fullPath.parent().mkpath()
            try fullPath.write(rawTemplate)

            try onGenerateFileFinishHandler(template, file, path)
        }

        if let scripts = template.scripts, !scripts.isEmpty {
            stdout <<< "Begin executing scripts".yellow

            for script in scripts {
                let process = Process()
                if #available(OSX 10.13, *) {
                    process.executableURL = URL(fileURLWithPath: "/usr/bin")
                } else {
                    process.launchPath = "/usr/bin"
                }

                process.arguments = [script]

                try process.runWithResult()
            }

            stdout <<< "Did finish executing scripts".yellow
        }

        stdout <<< "Did finish generate 🛠".green.bold
    }
}