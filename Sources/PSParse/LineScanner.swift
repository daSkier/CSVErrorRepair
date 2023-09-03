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

    func findLinesWithErrors(fromString inputString: String) -> [(lineIndex: Int, lineCount: Int)] {
        let separatedLines = getLines(fromString: inputString)
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        print("firstLineColumnCount: \(firstLineColumnCount)")
        var indicesWithIssue = [(lineIndex: Int, lineCount: Int)]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            indicesWithIssue.append((index, separatedLines[index].count))
        }
        var indicesWithIssue2 = [(lineIndex: Int, lineCount: Int)]()
        for line in separatedLines where line.count != firstLineColumnCount {
            if let issueIndex = separatedLines.firstIndex(of: line) {
                indicesWithIssue2.append((issueIndex, line.count))
            }else{
                print("failed to find index for line with issue")
            }
        }
        if indicesWithIssue.count != indicesWithIssue2.count {
            print("indices with issue search versions created different results - check discrepency\n \(indicesWithIssue) \nvs.\n \(indicesWithIssue2)")
        }
        return indicesWithIssue
    }

    func findLinesWithErrors(fromLines separatedLines: [[String]]) -> [(lineIndex: Int, lineCount: Int)] {
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        print("firstLineColumnCount: \(firstLineColumnCount)")
        var indicesWithIssue = [(lineIndex: Int, lineCount: Int)]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            indicesWithIssue.append((index, separatedLines[index].count))
        }
        var indicesWithIssue2 = [(lineIndex: Int, lineCount: Int)]()
        for line in separatedLines where line.count != firstLineColumnCount {
            if let issueIndex = separatedLines.firstIndex(of: line) {
                indicesWithIssue2.append((issueIndex, line.count))
            }else{
                print("failed to find index for line with issue")
            }
        }
        if indicesWithIssue.count != indicesWithIssue2.count {
            print("indices with issue search versions created different results - check discrepency\n \(indicesWithIssue) \nvs.\n \(indicesWithIssue2)")
        }
        return indicesWithIssue
    }

    func repairSequentialLines(lines: inout [[String]], firstLineIndex: Int) {
        let firstLineIndices = lines[firstLineIndex].indices
        let secondLineIndices = lines[firstLineIndex + 1].indices
        guard firstLineIndices.isEmpty != true else {
            print("firstLineIndices.isEmpty == true in repairLines")
            return
        }
        guard secondLineIndices.isEmpty != true else {
            print("secondLineIndices.isEmpty == true in repairLines")
            return
        }
        guard let firstLineLastIndex = firstLineIndices.last else {
            print("failed to get firstLineLastIndex")
            return
        }
        guard let secondLineFirstIndex = secondLineIndices.first else {
            print("failed to get secondLineFirstIndex")
            return
        }

        lines[firstLineIndex][firstLineLastIndex].append(lines[firstLineIndex + 1][secondLineFirstIndex])
        lines[firstLineIndex + 1].removeFirst()
        lines[firstLineIndex].append(contentsOf: lines[firstLineIndex + 1])
        lines[firstLineIndex + 1].removeAll()
    }

    func findAndRepairLinesWithErrors(inString inputString: String) -> [[String]] {
        var lines = getLines(fromString: inputString)
        let linesWithErrors = findLinesWithErrors(fromLines: lines)
        for (currentIndex, currentElement) in linesWithErrors.enumerated() {
            if currentIndex < linesWithErrors.count - 1 {
                let nextElement = linesWithErrors[currentIndex + 1]
                if currentElement.lineIndex + 1 == nextElement.lineIndex {
                    repairSequentialLines(lines: &lines, firstLineIndex: currentElement.lineIndex)
                }
                print("Next element: \(nextElement)")
                } else {
                    print("No more elements after current")
                }
        }
        lines.removeAll { $0.count == 0}
        print("lines after error correction:")
        for line in lines {
            print(line)
        }
        return lines
    }
}
