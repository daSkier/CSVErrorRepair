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
