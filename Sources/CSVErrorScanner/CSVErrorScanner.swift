//
//  File.swift
//  
//
//  Created by Justin on 8/29/23.
//

import Foundation
import CollectionConcurrencyKit

struct CSVErrorScanner {
    static func getLines(fromString inputString: String) -> [[String]] {
        inputString.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .newlines) }
            .map { $0.components(separatedBy: "\t") }
    }

    static func findLinesWithErrors(fromString inputString: String) -> [CSVLineIssue] {
        let separatedLines = Self.getLines(fromString: inputString)
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        var indicesWithIssue = [CSVLineIssue]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            indicesWithIssue.append(CSVLineIssue(lineIndex: index, columnCount: separatedLines[index].count, expectedColumnCount: firstLineColumnCount))
        }
        return indicesWithIssue
    }

    static func findLinesWithIncorrectElementCount(fromLines separatedLines: [[String]]) -> [CSVLineIssue] {
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        var indicesWithIssue = [CSVLineIssue]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            if index == separatedLines.indices.last && separatedLines[index].count == 1 && separatedLines[index].first!.isEmpty {
                // to skip empty last lines for files that include a last line with /cr or /r
                //print("skipping adding a last line becasuse it had one element which was empty")
            } else {
                indicesWithIssue.append(CSVLineIssue(lineIndex: index, columnCount: separatedLines[index].count, expectedColumnCount: firstLineColumnCount))
            }
        }
        return indicesWithIssue
    }

    static func repairLinesWithMoreColumnsBasedOnExpectedFields(forLine separatedLine: inout [String], targetColumnCount: Int, expectedFieldTypes: [FieldType], fileName: String, lineNumber: Int) {
        guard expectedFieldTypes.count == targetColumnCount else {
            print("expectedFieldTypes.count == targetColumnCount in \(#function)")
            return
        }
        let fieldCheck = Self.validate(separatedLine: separatedLine,
                                      againstExpectedFieldTypes: expectedFieldTypes,
                                      targetColumnCount: targetColumnCount)

        do {
            let lastIndicies = try fieldCheck.mergedLastIndices()
            let swagBestIndex = lastIndicies[1]
            
            var mergeResults: [(mergeIndex: Int, resultLine: [String], invalidIndicesForward: [Int], invalidIndicesCount: Int)] = []

            for mergeIndex in lastIndicies {
                //TODO: is it better to step one cell further forward
                var mergedLine = separatedLine
                mergedLine[mergeIndex] = mergedLine[mergeIndex] + mergedLine[mergeIndex+1]
                mergedLine.remove(at: mergeIndex+1)

                let postMergeValidation = Self.validate(separatedLine: mergedLine,
                                                   againstExpectedFieldTypes: expectedFieldTypes,
                                                   targetColumnCount: targetColumnCount)
                mergeResults.append((mergeIndex: mergeIndex,
                                     resultLine: mergedLine,
                                     invalidIndicesForward: postMergeValidation.invalidIndiciesForward,
                                     invalidIndicesCount: postMergeValidation.invalidIndiciesForward.count
                                    ))
            }
            let finalMergeResults = mergeResults.sorted { $0.invalidIndicesCount < $1.invalidIndicesCount }
            let minErrors = finalMergeResults
                .min { $0.invalidIndicesCount < $1.invalidIndicesCount }
                .map { $0.invalidIndicesCount }
            if let minErrors {
                let bestMergeIndex: Int = {
                    let minErrorResults = finalMergeResults.filter { $0.invalidIndicesCount == minErrors }
                    if minErrorResults.count == 1 {
                        return minErrorResults.first!.mergeIndex
                    }else if minErrorResults.count > 1 {
                        if minErrorResults.contains(where: { $0.mergeIndex == swagBestIndex }) {
                            print("using swagMergeIndex")
                            return swagBestIndex
                        }else{
                            print("using first minErrorResult as mergeIndex by default")
                            return minErrorResults.first!.mergeIndex
                        }
                    }else {
                        return 0
                    }
                }()

                if bestMergeIndex == 0 {
                    print("won't merge because bestMergeIndex == 0")
                }else {
                    //TODO: is it better to step one cell further forward
                    separatedLine[bestMergeIndex] = separatedLine[bestMergeIndex] + separatedLine[bestMergeIndex+1]
                    separatedLine.remove(at: bestMergeIndex+1)
                }
            }else{
                print("failed to get minErrors in \(#function)")
            }
        } catch {
            print("error repairing line (\(error)) line \(fileName):\(lineNumber): \(separatedLine)")
        }
    }

    static func validate(separatedLine: [String], againstExpectedFieldTypes: [FieldType], targetColumnCount: Int) -> ValidationResultSet {
        let lineIndices = separatedLine.indices

        var result = ValidationResultSet(validatedIndicesForward: [],
                                         invalidIndiciesForward: [],
                                         lessValidatedIndicesForward: [],
                                         validatedIndicesBackward: [],
                                         invalidIndicesBackward: [],
                                         lessValidatedIndicesBackward: [])

        // Check going forward until invalid
        for index in lineIndices {
            if againstExpectedFieldTypes.indices.contains(index) == false {
                break
            }
            let expectedFieldType = againstExpectedFieldTypes[index]
            let valid = expectedFieldType.validate(inputString: separatedLine[index])
            if valid == .invalid {
                result.invalidIndiciesForward.append(index)
                break
            }
            switch valid {
            case .valid:
                result.lessValidatedIndicesForward.append(index)
                result.validatedIndicesForward.append(index)
            case .null:
                result.lessValidatedIndicesForward.append(index)
            case .unknownString:
                result.lessValidatedIndicesForward.append(index)
            case .invalid:
                break
            }
        }

        // Check going backward until invalid
        let initialReverseIndexOffset = lineIndices.count - targetColumnCount
        for reverseIndex in lineIndices.reversed() {
            if !againstExpectedFieldTypes.indices.contains(reverseIndex-initialReverseIndexOffset) {
                break
            }
            let expectedFieldType = againstExpectedFieldTypes[reverseIndex-initialReverseIndexOffset]
            let valid = expectedFieldType.validate(inputString: separatedLine[reverseIndex])
            if valid == .invalid {
                result.invalidIndicesBackward.append(reverseIndex)
                break
            }
            switch valid {
            case .valid:
                result.lessValidatedIndicesBackward.append(reverseIndex)
                result.validatedIndicesBackward.append(reverseIndex)
            case .null:
                result.lessValidatedIndicesBackward.append(reverseIndex)
            case .unknownString:
                result.lessValidatedIndicesBackward.append(reverseIndex)
            case .invalid:
                break
            }
        }
        return result
    }

    static func repairSequentialShortLines(lines: inout [[String]], firstLineIndex: Int, targetColumnCount: Int) {
        var linesAhead = 0
        repeat {
            linesAhead += 1
            let firstLineIndices = lines[firstLineIndex].indices
            let mergeLineIndices = lines[firstLineIndex + linesAhead].indices

            guard firstLineIndices.isEmpty != true else {
                return
            }
            guard mergeLineIndices.isEmpty != true else {
                return
            }
            guard let firstLineLastIndex = firstLineIndices.last else {
                print("failed to get firstLineLastIndex")
                return
            }
            guard let mergeLineFirstIndex = mergeLineIndices.first else {
                print("failed to get ahead line firstIndex")
                return
            }
            // we subtract 1 from the end because one column will be merged with another
            guard firstLineIndices.count + mergeLineIndices.count - 1 <= (targetColumnCount+1) else {
                if firstLineIndices.count + mergeLineIndices.count - 1 < (targetColumnCount*2-1) {
                    print("combining the merge line would fall into warning range - too long (\(firstLineIndices.count + mergeLineIndices.count - 1) vs. \(targetColumnCount) - firstLine: \(lines[firstLineIndex]) secondLine: \(lines[firstLineIndex + linesAhead])")
                }
                return
            }

            lines[firstLineIndex][firstLineLastIndex].append(lines[firstLineIndex + linesAhead][mergeLineFirstIndex]) // merge first/last element to account for new line split
            lines[firstLineIndex + linesAhead].removeFirst() // remove because it was just merged
            lines[firstLineIndex].append(contentsOf: lines[firstLineIndex + linesAhead]) // append rest of line
            lines[firstLineIndex + linesAhead].removeAll() // remove merge line
        } while lines[firstLineIndex].indices.count < targetColumnCount
    }

    static func findAndRepairLinesWithTooFewElements(_ lines: inout [[String]]) {
        let linesWithErrors = Self.findLinesWithIncorrectElementCount(fromLines: lines)
        print("lines with errors: \(linesWithErrors.count)")
        print("lines with errors: \(linesWithErrors)")
        for (currentIndex, currentElement) in linesWithErrors.enumerated() {
            if currentIndex < linesWithErrors.count - 1 {
                let nextElement = linesWithErrors[currentIndex + 1]
                if currentElement.lineIndex + 1 == nextElement.lineIndex {
                    Self.repairSequentialShortLines(lines: &lines, firstLineIndex: currentElement.lineIndex, targetColumnCount: currentElement.expectedColumnCount)
                }
            } else {
                print("No more elements after current")
            }
        }
        lines.removeAll { $0.count == 0}
        lines.removeAll { $0.count == 1 && $0.first!.isEmpty }
    }

    static func detectFileEncoding(atPath filePath: String) -> String.Encoding? {
        let url = URL(fileURLWithPath: filePath)

        do {
            let data = try Data(contentsOf: url)
            var resultString: NSString?

            var usedLossyConversion: ObjCBool = false

            let detectedEncoding = NSString.stringEncoding(for: data,
                                                 encodingOptions: nil,
                                                 convertedString: &resultString,
                                                 usedLossyConversion: &usedLossyConversion)

            if usedLossyConversion.boolValue {
                // If a lossy conversion was used, the exact encoding may not be reliable
                print("Lossy conversion used")
            }
            return String.Encoding(rawValue: detectedEncoding)
        } catch {
            print("Error reading the file: \(error)")
            return nil
        }
    }

    static func correctErrorsIn(directory: URL, fileFilter: (URL) -> Bool, fileToFieldType: @escaping (URL) -> [String : FieldType]?) async throws -> [CSVFileIssues] {
        let enum1 = FileManager.default
            .enumerator(at: directory,
                        includingPropertiesForKeys: nil,
                        options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        let items = enum1?.allObjects as! [URL]
        let csvItems = items.filter { $0.lastPathComponent.hasSuffix("csv") }
            .filter {  fileFilter($0) }
        print("csvItems.count: \(csvItems.count)")
        let fileErrors = try await csvItems
            .concurrentMap { csvFile -> CSVFileIssues in
                guard let mappingDict = fileToFieldType(csvFile) else {
                    fatalError("failed to get file mapping dict")
                }
                return try autoreleasepool {
                    let fileString = try String(contentsOf: csvFile, encoding: .isoLatin1)
                    var lines = CSVErrorScanner.getLines(fromString: fileString)
                    let linesWithIssues = CSVErrorScanner.findLinesWithIncorrectElementCount(fromLines: lines)
                    if linesWithIssues.count > 0 {
                        for issueLine in linesWithIssues {
                            CSVErrorScanner.repairSequentialShortLines(lines: &lines,
                                                          firstLineIndex: issueLine.lineIndex,
                                                          targetColumnCount: issueLine.expectedColumnCount)
                        }
                        lines.removeAll{ $0.count == 0 } // prevents issues with lines that end with /r
                        lines.removeAll { $0.count == 1 && $0.first!.isEmpty } // prevents issues with lines that end with /r
                        let linesWithIssuesAfterSequentialLineRepair = CSVErrorScanner.findLinesWithIncorrectElementCount(fromLines: lines)
                        let fieldTypes = lines.first!.map { fieldName in
                            guard let type = mappingDict[fieldName] else {
                                fatalError("failed to get field type for \(fieldName)")
                            }
                            return type
                        }
                        for issueLine in linesWithIssuesAfterSequentialLineRepair {
                            CSVErrorScanner.repairLinesWithMoreColumnsBasedOnExpectedFields(forLine: &lines[issueLine.lineIndex],
                                                                                    targetColumnCount: issueLine.expectedColumnCount,
                                                                                    expectedFieldTypes: fieldTypes,
                                                                                    fileName: csvFile.lastPathComponent,
                                                                                    lineNumber: issueLine.lineIndex)
                        }
                        let linesWithIssuesAfterLongLineRepair = CSVErrorScanner.findLinesWithIncorrectElementCount(fromLines: lines)
                        if !linesWithIssuesAfterLongLineRepair.isEmpty {
                            print("linesWithIssuesAfterLongLineRepair: \(linesWithIssuesAfterLongLineRepair)")
                        }
                        return CSVFileIssues(fileUrl: csvFile, issues: linesWithIssuesAfterLongLineRepair)
                    }else{
                        return CSVFileIssues(fileUrl: csvFile, issues: linesWithIssues)
                    }
                }
            }
        return fileErrors

    }

    static func correctErrorsIn(files: [(URL, Data)], fileToFieldType: @escaping (URL) -> [String : FieldType]?) async throws -> [CSVFileIssues] {
        let csvData = files.filter { $0.0.lastPathComponent.hasSuffix("csv") }
        print("csvItems.count: \(csvData.count)")
        let fileErrors = try await csvData
            .concurrentMap { csvFile -> CSVFileIssues in
                guard let mappingDict = fileToFieldType(csvFile.0) else {
                    fatalError("failed to get file mapping dict")
                }
                return try autoreleasepool {
                    guard let fileString = String(data: csvFile.1, encoding: .isoLatin1) else {
                        throw ParseError.failedToGetStringFromData
                    }
                    var lines = CSVErrorScanner.getLines(fromString: fileString)
                    let linesWithIssues = CSVErrorScanner.findLinesWithIncorrectElementCount(fromLines: lines)
                    if linesWithIssues.count > 0 {
                        for issueLine in linesWithIssues {
                            CSVErrorScanner.repairSequentialShortLines(lines: &lines,
                                                          firstLineIndex: issueLine.lineIndex,
                                                          targetColumnCount: issueLine.expectedColumnCount)
                        }
                        lines.removeAll{ $0.count == 0 } // prevents issues with lines that end with /r
                        lines.removeAll { $0.count == 1 && $0.first!.isEmpty } // prevents issues with lines that end with /r
                        let linesWithIssuesAfterSequentialLineRepair = CSVErrorScanner.findLinesWithIncorrectElementCount(fromLines: lines)
                        let fieldTypes = lines.first!.map { fieldName in
                            guard let type = mappingDict[fieldName] else {
                                fatalError("failed to get field type for \(fieldName)")
                            }
                            return type
                        }
                        for issueLine in linesWithIssuesAfterSequentialLineRepair {
                            CSVErrorScanner.repairLinesWithMoreColumnsBasedOnExpectedFields(forLine: &lines[issueLine.lineIndex],
                                                                                    targetColumnCount: issueLine.expectedColumnCount,
                                                                                    expectedFieldTypes: fieldTypes,
                                                                                            fileName: csvFile.0.lastPathComponent,
                                                                                    lineNumber: issueLine.lineIndex)
                        }
                        let linesWithIssuesAfterLongLineRepair = CSVErrorScanner.findLinesWithIncorrectElementCount(fromLines: lines)
                        if !linesWithIssuesAfterLongLineRepair.isEmpty {
                            print("linesWithIssuesAfterLongLineRepair: \(linesWithIssuesAfterLongLineRepair)")
                        }
                        return CSVFileIssues(fileUrl: csvFile.0, issues: linesWithIssuesAfterLongLineRepair)
                    }else{
                        return CSVFileIssues(fileUrl: csvFile.0, issues: linesWithIssues)
                    }
                }
            }
        return fileErrors

    }
}

enum ParseError: Error {
    case failedToGetLastItemFromValidatedIndicyArray
    case failedToGetStringFromData
}

struct ValidationResultSet {
    var validatedIndicesForward: [Int]
    var invalidIndiciesForward: [Int]
    var lessValidatedIndicesForward: [Int]
    var validatedIndicesBackward: [Int]
    var invalidIndicesBackward: [Int]
    var lessValidatedIndicesBackward: [Int]
    var lastValidForward: Int? { validatedIndicesForward.last }
    var lastLessValidForward: Int? { lessValidatedIndicesForward.last }
    var lastValidBackward: Int? { validatedIndicesBackward.last }
    var lastLessValidBackward: Int? { lessValidatedIndicesBackward.last }

    func validForwardBackDifferenceString() -> String {
        if let lastValidForward, let lastValidBackward {
            return "difference between forward/reverse valid indicies \(lastValidBackward-lastValidForward) (\(lastValidForward) vs. \(lastValidBackward)"
        }else{
            return "failed to get lastValidForward and/or lastValidBackward"
        }
    }

    func lessValidForwardBackDifferenceString() -> String {
        if let lastLessValidForward, let lastLessValidBackward {
            return "difference between forward/reverse lessValid indicies \(lastLessValidBackward-lastLessValidForward) (\(lastLessValidForward) vs. \(lastLessValidBackward)"
        }else{
            return "failed to get lastLessValidForward and/or lastLessValidBackward"
        }
    }

    func mergedLastIndices() throws -> [Int] {
        if let lastValidForward, let lastValidBackward, let lastLessValidForward, let lastLessValidBackward {
            return [
                lastValidForward,
                lastLessValidForward,
                lastValidBackward,
                lastLessValidBackward
            ].sorted()
        }else {
            print("failed to get mergedLastIndicies - lastValidForward: \(String(describing: lastValidForward)) / lastValidBackward: \(String(describing: lastValidBackward)) / lastLessValidForward: \(String(describing: lastLessValidForward)) / lastLessValidBackward: \(String(describing: lastLessValidBackward))")
            throw ValidationResultSetError.oneLastIndicyNil
        }
    }

    func printResults() {
        print(validForwardBackDifferenceString())
        print(lessValidForwardBackDifferenceString())
        print("invalidIndicesForward: \(invalidIndiciesForward)")
        print("invalidIndicesBackward: \(invalidIndicesBackward)")
        print("valid indicies array: \(String(describing: try? mergedLastIndices()))")
    }
    enum ValidationResultSetError: Error {
        case oneLastIndicyNil
    }
}

struct CSVFileIssues {
    var fileUrl: URL
    var issues: [CSVLineIssue]
}

struct CSVLineIssue {
    var lineIndex: Int
    var columnCount: Int
    var expectedColumnCount: Int
}