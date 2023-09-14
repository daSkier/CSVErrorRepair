//
//  File.swift
//  
//
//  Created by Justin on 8/29/23.
//

import Foundation

struct LineScanner {
    func getLines(fromString inputString: String) -> [[String]] {
        inputString.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .newlines) }
            .map { $0.components(separatedBy: "\t") }
    }

    func findLinesWithErrors(fromString inputString: String) -> [(lineIndex: Int, lineCount: Int, targetColumnCount: Int)] {
        let separatedLines = getLines(fromString: inputString)
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        var indicesWithIssue = [(lineIndex: Int, lineCount: Int, targetColumnCount: Int)]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            indicesWithIssue.append((index, separatedLines[index].count, firstLineColumnCount))
        }
        return indicesWithIssue
    }

    func findLinesWithIncorrectElementCount(fromLines separatedLines: [[String]]) -> [(lineIndex: Int, lineCount: Int, targetColumnCount: Int)] {
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        var indicesWithIssue = [(lineIndex: Int, lineCount: Int, targetColumnCount: Int)]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            if index == separatedLines.indices.last && separatedLines[index].count == 1 && separatedLines[index].first!.isEmpty {
//                print("skipping adding a last line becasuse it had one element which was empty")
            } else {
                indicesWithIssue.append((index, separatedLines[index].count, firstLineColumnCount))
            }
        }
        return indicesWithIssue
    }

    func repairLinesWithMoreColumnsBasedOnExpectedFields(forLine separatedLine: inout [String], targetColumnCount: Int, expectedFieldTypes: [FieldType]) {
        guard expectedFieldTypes.count == targetColumnCount else {
            print("expectedFieldTypes.count == targetColumnCount in \(#function)")
            return
        }
        let lineIndices = separatedLine.indices
        var lineOffset = 0
        var validatedIndicesForward: [Int] = []
        var lessValidatedIndicesForward: [Int] = []
        var validatedIndicesBackward: [Int] = []
        var lessValidatedIndicesBackward: [Int] = []
        
        // Check going forward until invalid
        for index in lineIndices {
            let expectedFieldType = expectedFieldTypes[index]
            if expectedFieldType == .unknownString {
                lessValidatedIndicesForward.append(index)
            } else if expectedFieldType.validate(inputString: separatedLine[index]) {
                validatedIndicesForward.append(index)
                lessValidatedIndicesForward.append(index)
            }else{
                break
            }
        }

        // Check going backward until invalid
        let initialReverseIndexOffset = lineIndices.count - targetColumnCount
        for reverseIndex in lineIndices.reversed() {
            let expectedFieldType = expectedFieldTypes[reverseIndex-initialReverseIndexOffset]
            if expectedFieldType == .unknownString {
                lessValidatedIndicesBackward.append(reverseIndex)
            } else if expectedFieldType.validate(inputString: separatedLine[reverseIndex]) {
                lessValidatedIndicesBackward.append(reverseIndex)
                validatedIndicesBackward.append(reverseIndex)
            } else {
                break
            }
        }

        guard let lastValidForward = validatedIndicesForward.last,
              let lastLessValidForward = lessValidatedIndicesForward.last else {
            print("failed to get one of the lastValid forward items")
            return
        }
        guard let lastValidBackward = validatedIndicesBackward.last,
              let lastLessValidBackward = lessValidatedIndicesBackward.last else {
            print("failed to get one of the lastValid backward items")
            return
        }
        print("difference between forward/reverse valid indicies \(lastValidBackward-lastValidForward) (\(lastValidForward) vs. \(lastValidBackward)")
        print("difference between forward/reverse lessValid indicies \(lastLessValidBackward-lastLessValidForward) (\(lastLessValidForward) vs. \(lastLessValidBackward)")

    }

    func repairSequentialLines(lines: inout [[String]], firstLineIndex: Int, targetColumnCount: Int) {
//        print("repairing line with index \(firstLineIndex) and next")
        var linesAhead = 0
        repeat {
            linesAhead += 1
            let firstLineIndices = lines[firstLineIndex].indices
            let mergeLineIndices = lines[firstLineIndex + linesAhead].indices

            guard firstLineIndices.isEmpty != true else {
//                print("firstLineIndices.isEmpty == true in repairLines")
                return
            }
            guard mergeLineIndices.isEmpty != true else {
//                print("secondLineIndices.isEmpty == true in repairLines")
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
            guard firstLineIndices.count + mergeLineIndices.count - 1 <= targetColumnCount else {
//                print("combining the merge line would make the line too long")
                return
            }

            lines[firstLineIndex][firstLineLastIndex].append(lines[firstLineIndex + linesAhead][mergeLineFirstIndex])
            lines[firstLineIndex + linesAhead].removeFirst()
            lines[firstLineIndex].append(contentsOf: lines[firstLineIndex + linesAhead])
            lines[firstLineIndex + linesAhead].removeAll()
        } while lines[firstLineIndex].indices.count < targetColumnCount
    }

    func findAndRepairLinesWithTooFewElements(_ lines: inout [[String]]) {
        let linesWithErrors = findLinesWithIncorrectElementCount(fromLines: lines)
        print("lines with errors: \(linesWithErrors.count)")
//        print("lines with errors: \(linesWithErrors)")
        for (currentIndex, currentElement) in linesWithErrors.enumerated() {
            if currentIndex < linesWithErrors.count - 1 {
                let nextElement = linesWithErrors[currentIndex + 1]
                if currentElement.lineIndex + 1 == nextElement.lineIndex {
                    repairSequentialLines(lines: &lines, firstLineIndex: currentElement.lineIndex, targetColumnCount: currentElement.targetColumnCount)
                }
                } else {
                    print("No more elements after current")
                }
        }
        lines.removeAll { $0.count == 0}
        lines.removeAll { $0.count == 1 && $0.first!.isEmpty }
    }

    func detectFileEncoding(atPath filePath: String) -> String.Encoding? {
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
}

enum ParseError: Error {
    case failedToGetLastItemFromValidatedIndicyArray
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

    func mergedLastIndices() -> [Int] {
        if let lastValidForward, let lastValidBackward, let lastLessValidForward, let lastLessValidBackward {
            return [
                lastValidForward,
                lastLessValidForward,
                lastValidBackward,
                lastLessValidBackward
            ].sorted()
        }else {
            return []
        }
    }
}
