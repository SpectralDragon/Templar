//
// Created by admin on 2019-03-06.
//

import xcodeproj
import PathKit


extension PBXGroup {

    func addGroupOrUseExists(named: String) throws -> [PBXGroup] {
        var pathComponents = Path(named).components
        var lastGroup = self

        for component in pathComponents {
            if let findedGroup = lastGroup.children.first(where: { $0.path == component }) as? PBXGroup {
                lastGroup = findedGroup
                pathComponents.removeFirst()
            } else {
                break
            }
        }

        if pathComponents.isEmpty {
            return [lastGroup]
        } else {
            let groupPath = Path(pathComponents.joined(separator: "/"))
            return try lastGroup.addGroup(named: groupPath.string)
        }
    }
}


extension PBXSourcesBuildPhase {

    @discardableResult
    func updateOrAdd(file: PBXFileReference) throws -> PBXBuildFile {
        if let index = self.files.firstIndex(where: { $0.file?.path == file.path && $0.file?.name == file.name }) {
            self.files.remove(at: index)
        }

        return try self.add(file: file)
    }
}


#if DEBUG
extension PBXGroup: CustomStringConvertible {
    public var description: String {
        return self.name ?? self.path ?? "Noting"
    }
}
#endif
