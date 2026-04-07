//
//  CSVErrorRepair.swift
//
//
//  Created by Justin on 8/29/23.
//

import Foundation
import CollectionConcurrencyKit

/// A collection of static methods for detecting and repairing common errors in CSV files.
///
/// CSV files sourced from real-world systems often contain two categories of errors:
/// - **Short lines**: A newline inside a field value split one logical row across multiple physical lines.
/// - **Long lines**: The column delimiter appeared inside a field value, producing extra columns.
///
/// `CSVErrorRepair` operates on parsed line arrays (`[[String]]`) and applies repairs in-place
/// to minimize memory allocations. Use ``getLines(fromString:lineDelimeter:columnDelimeter:)`` to
/// parse a CSV string into this format, then call the repair methods as needed.
///
/// ## Topics
///
/// ### Parsing
/// - ``getLines(fromString:lineDelimeter:columnDelimeter:)``
/// - ``getLines(fromData:lineDelimeter:columnDelimeter:encoding:)``
///
/// ### Converting Back to String or Data
/// - ``convertToString(lines:columnDelimeter:lineDelimeter:checkForQuotes:)``
/// - ``convertToData(lines:columnDelimeter:lineDelimeter:encoding:)``
///
/// ### Error Detection
/// - ``findLinesWithErrors(fromString:)``
/// - ``findLinesWithIncorrectElementCount(fromLines:)``
///
/// ### Repair
/// - ``findAndRepairLinesWithTooFewElements(_:)``
/// - ``repairSequentialShortLines(lines:firstLineIndex:targetColumnCount:)``
/// - ``repairLinesWithMoreColumnsBasedOnExpectedFields(forLine:targetColumnCount:expectedFieldTypes:fileName:lineNumber:)``
/// - ``correctErrorsIn(_:forUrl:fieldTypes:)-1lea``
///
/// ### Batch Processing
/// - ``correctErrorsIn(directory:fileFilter:fileToFieldType:)``
/// - ``correctErrorsIn(files:fileToFieldType:)``
public struct CSVErrorRepair {

    /// Parses a CSV string into a two-dimensional array of field values.
    ///
    /// Each inner array represents one line, with each element being a single field value.
    /// Newline characters are trimmed from individual lines before splitting by column delimiter.
    ///
    /// - Parameters:
    ///   - inputString: The raw CSV content as a string.
    ///   - lineDelimeter: The character(s) separating rows. Defaults to `"\n"`.
    ///   - columnDelimeter: The character(s) separating columns. Defaults to `"\t"`.
    /// - Returns: A two-dimensional array where each inner array is one parsed row.
    public static func getLines(fromString inputString: String, lineDelimeter: String = "\n", columnDelimeter: String = "\t") -> [[String]] {
        inputString.components(separatedBy: lineDelimeter).map {
            $0.trimmingCharacters(in: .newlines).components(separatedBy: columnDelimeter)
        }
    }

    /// Parses CSV data into a two-dimensional array of field values.
    ///
    /// Converts the raw `Data` to a string using the specified encoding, then delegates to
    /// ``getLines(fromString:lineDelimeter:columnDelimeter:)``.
    ///
    /// - Parameters:
    ///   - data: The raw CSV content as `Data`.
    ///   - lineDelimeter: The character(s) separating rows. Defaults to `"\n"`.
    ///   - columnDelimeter: The character(s) separating columns. Defaults to `"\t"`.
    ///   - encoding: The string encoding to use when converting data. Defaults to `.isoLatin1`.
    /// - Throws: ``ParseError/failedToGetStringFromData`` if the data cannot be decoded with the given encoding.
    ///   Consider making this a typed throw (`throws(ParseError)`) in a future version.
    /// - Returns: A two-dimensional array where each inner array is one parsed row.
    public static func getLines(fromData data: Data, lineDelimeter: String = "\n", columnDelimeter: String = "\t", encoding: String.Encoding = .isoLatin1) throws -> [[String]] {
        guard let string = String(data: data, encoding: encoding) else {
            throw ParseError.failedToGetStringFromData
        }
        return Self.getLines(fromString: string, lineDelimeter: lineDelimeter, columnDelimeter: columnDelimeter)
    }

    /// Converts a two-dimensional line array back into a single CSV string.
    ///
    /// - Parameters:
    ///   - lines: The parsed line arrays to convert.
    ///   - columnDelimeter: The character(s) to place between columns. Defaults to `"\t"`.
    ///   - lineDelimeter: The character(s) to place between rows. Defaults to `"\n"`.
    ///   - checkForQuotes: When `true`, strips double-quote characters from field values.
    /// - Returns: A single string containing the reconstructed CSV content.
    public static func convertToString(lines: [[String]], columnDelimeter: String = "\t", lineDelimeter: String = "\n", checkForQuotes: Bool = false) -> String {
        lines.map { cells -> String in
            if checkForQuotes {
                return cells.map { cell in
                    cell.contains("\"") ? cell.replacingOccurrences(of: "\"", with: "") : cell
                }.joined(separator: columnDelimeter)
            } else {
                return cells.joined(separator: columnDelimeter)
            }
        }.joined(separator: lineDelimeter)
    }

    /// Converts a two-dimensional line array back into `Data` using the specified encoding.
    ///
    /// - Parameters:
    ///   - lines: The parsed line arrays to convert.
    ///   - columnDelimeter: The character(s) to place between columns. Defaults to `"\t"`.
    ///   - lineDelimeter: The character(s) to place between rows. Defaults to `"\n"`.
    ///   - encoding: The string encoding to use. Defaults to `.isoLatin1`.
    /// - Returns: The reconstructed CSV as `Data`, or `nil` if encoding fails.
    public static func convertToData(lines: [[String]], columnDelimeter: String = "\t", lineDelimeter: String = "\n", encoding: String.Encoding = .isoLatin1) -> Data? {
        return Self.convertToString(lines: lines, columnDelimeter: columnDelimeter, lineDelimeter: lineDelimeter).data(using: encoding)
    }

    /// Parses a CSV string and returns issues for any lines with an incorrect column count.
    ///
    /// A convenience method that combines parsing and error detection in one call.
    /// The expected column count is determined by the first line (header row).
    /// Trailing empty lines (common in files ending with `\r` or `\n`) are skipped.
    ///
    /// - Parameter inputString: The raw CSV content as a string.
    /// - Returns: An array of ``LineIssue`` values describing each line with an unexpected column count.
    public static func findLinesWithErrors(fromString inputString: String) -> [LineIssue] {
        let separatedLines = Self.getLines(fromString: inputString)
        return Self.findLinesWithIncorrectElementCount(fromLines: separatedLines)
    }

    /// Finds lines whose column count differs from the first line (header row).
    ///
    /// Compares each line's column count against the first line. Lines with a different count
    /// are returned as issues. A trailing empty line (common in files ending with a carriage return)
    /// is silently skipped.
    ///
    /// - Parameter separatedLines: The parsed CSV line arrays.
    /// - Returns: An array of ``LineIssue`` values describing each line with an unexpected column count.
    public static func findLinesWithIncorrectElementCount(fromLines separatedLines: [[String]]) -> [LineIssue] {
        guard let firstLineColumnCount = separatedLines.first?.count else {
            print("failed to get firstLineColumnCount for provided string")
            return []
        }
        var indicesWithIssue = [LineIssue]()
        for index in separatedLines.indices where separatedLines[index].count != firstLineColumnCount {
            if index == separatedLines.indices.last && separatedLines[index].count == 1 && separatedLines[index].first!.isEmpty {
                // to skip empty last lines for files that include a last line with /cr or /r
                //print("skipping adding a last line becasuse it had one element which was empty")
            } else {
                indicesWithIssue.append(LineIssue(lineIndex: index, columnCount: separatedLines[index].count, expectedColumnCount: firstLineColumnCount))
            }
        }
        return indicesWithIssue
    }

    /// Repairs a line that has too many columns by merging adjacent cells using field-type validation.
    ///
    /// The algorithm validates fields from both the start and end of the line against the expected
    /// field types. Where validation fails, it identifies candidate merge points — positions where
    /// two adjacent cells should be joined back into a single field. It tries each candidate,
    /// selects the merge that produces the fewest validation errors, and applies it.
    ///
    /// This method handles one extra column per call. For lines with multiple extra columns,
    /// call this method repeatedly until the line reaches the target count.
    ///
    /// - Parameters:
    ///   - separatedLine: The line to repair, modified in-place.
    ///   - targetColumnCount: The expected number of columns. Must equal `expectedFieldTypes.count`.
    ///     In a future version this parameter could be removed and derived from the field types array.
    ///   - expectedFieldTypes: An ordered array of ``FieldType`` values matching each column.
    ///   - fileName: The source file name, used for diagnostic output.
    ///   - lineNumber: The line number in the source file, used for diagnostic output.
    public static func repairLinesWithMoreColumnsBasedOnExpectedFields(forLine separatedLine: inout [String], targetColumnCount: Int, expectedFieldTypes: [FieldType], fileName: String, lineNumber: Int) {
        guard expectedFieldTypes.count == targetColumnCount else {
            print("expectedFieldTypes.count (\(expectedFieldTypes.count)) != targetColumnCount (\(targetColumnCount)) in \(#function)")
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

    /// Validates a line's fields against an array of expected field types, scanning in both directions.
    ///
    /// Scans forward from the first field and backward from the last field, checking each value
    /// against its corresponding ``FieldType``. Scanning stops in each direction at the first
    /// invalid field. The resulting ``ValidationResultSet`` captures which indices were validated,
    /// which were invalid, and which had weaker matches (null or unknown string).
    ///
    /// This bidirectional approach helps identify the boundary where an extra delimiter caused
    /// fields to shift, enabling ``repairLinesWithMoreColumnsBasedOnExpectedFields(forLine:targetColumnCount:expectedFieldTypes:fileName:lineNumber:)``
    /// to find the best merge point.
    ///
    /// - Parameters:
    ///   - separatedLine: The fields of the line to validate.
    ///   - againstExpectedFieldTypes: The expected ``FieldType`` for each column position.
    ///   - targetColumnCount: The expected number of columns (used to calculate the backward scan offset).
    ///     In a future version this could be derived from `againstExpectedFieldTypes.count`.
    /// - Returns: A ``ValidationResultSet`` with the results of both forward and backward scans.
    public static func validate(separatedLine: [String], againstExpectedFieldTypes: [FieldType], targetColumnCount: Int) -> ValidationResultSet {
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

    /// Merges consecutive short lines starting at the given index until the target column count is reached.
    ///
    /// When a field value contains a newline, the CSV row gets split across multiple physical lines.
    /// This method detects that pattern and merges the fragments back together. It concatenates the
    /// last field of the current line with the first field of the next line (repairing the split),
    /// then appends the remaining fields. The process repeats with subsequent lines until the merged
    /// line reaches the `targetColumnCount`.
    ///
    /// Merged source lines are emptied so they can be removed afterward with
    /// `lines.removeAll { $0.isEmpty }`.
    ///
    /// - Parameters:
    ///   - lines: The full array of parsed lines, modified in-place.
    ///   - firstLineIndex: The index of the first short line to begin merging from.
    ///   - targetColumnCount: The expected number of columns for a complete line.
    public static func repairSequentialShortLines(lines: inout [[String]], firstLineIndex: Int, targetColumnCount: Int) {
        var linesAhead = 0
        repeat {
            linesAhead += 1
            guard firstLineIndex + linesAhead < lines.count else { return }
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

    /// Finds all short lines and repairs them by merging consecutive short lines together.
    ///
    /// A convenience method that combines ``findLinesWithIncorrectElementCount(fromLines:)`` with
    /// ``repairSequentialShortLines(lines:firstLineIndex:targetColumnCount:)`` for each pair of
    /// consecutive short lines. After merging, removes any empty or single-empty-element lines
    /// left behind by the merge process.
    ///
    /// - Parameter lines: The full array of parsed lines, modified in-place.
    public static func findAndRepairLinesWithTooFewElements(_ lines: inout [[String]]) {
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

#if os(macOS)
//    @available(macOS 10.10, *)
//    public static func detectFileEncoding(atPath filePath: String) -> String.Encoding? {
//        let url = URL(fileURLWithPath: filePath)
//
//        do {
//            let data = try Data(contentsOf: url)
//            var resultString: NSString?
//
//            var usedLossyConversion: ObjCBool = false
//
//            let detectedEncoding = NSString.stringEncoding(for: data,
//                                                 encodingOptions: nil,
//                                                 convertedString: &resultString,
//                                                 usedLossyConversion: &usedLossyConversion)
//
//            if usedLossyConversion.boolValue {
//                // If a lossy conversion was used, the exact encoding may not be reliable
//                print("Lossy conversion used")
//            }
//            return String.Encoding(rawValue: detectedEncoding)
//        } catch {
//            print("Error reading the file: \(error)")
//            return nil
//        }
//    }
#endif

    /// Runs the full repair pipeline on parsed CSV lines: merges short lines,
    /// removes empty lines left behind by the merge, then repairs lines that have
    /// too many columns using field-type validation.
    ///
    /// This is the single authoritative implementation of the repair sequence.
    /// All public `correctErrorsIn` methods delegate to this helper.
    ///
    /// - Parameters:
    ///   - lines: The parsed CSV lines to repair, modified in-place.
    ///   - fieldTypeMapping: A dictionary mapping column header names to their expected ``FieldType``.
    ///   - fileName: The source file name, used for diagnostic output.
    ///   - fileUrl: The source file URL, used for error reporting.
    /// - Throws: ``ParseError/emptyFileAfterCleanup(_:)`` if all lines are removed during cleanup.
    ///   ``ParseError/unknownFieldName(_:_:)`` if a header column has no entry in the mapping.
    /// - Returns: An array of ``LineIssue`` values for any lines that remain incorrect after repair.
    private static func repairLines(
        _ lines: inout [[String]],
        fieldTypeMapping: [String: FieldType],
        fileName: String,
        fileUrl: URL
    ) throws -> [LineIssue] {
        let linesWithIssues = findLinesWithIncorrectElementCount(fromLines: lines)
        guard !linesWithIssues.isEmpty else { return linesWithIssues }

        // Step 1: Merge consecutive short lines (rows split by embedded newlines)
        for issueLine in linesWithIssues {
            repairSequentialShortLines(lines: &lines,
                                       firstLineIndex: issueLine.lineIndex,
                                       targetColumnCount: issueLine.expectedColumnCount)
        }

        // Step 2: Remove empty lines and single-empty-element lines left behind by the
        // merge process — prevents issues with files that end with \r or \n
        lines.removeAll { $0.isEmpty || ($0.count == 1 && $0.first!.isEmpty) }

        // Step 3: Repair lines that have too many columns using field-type validation
        let linesWithIssuesAfterSequentialLineRepair = findLinesWithIncorrectElementCount(fromLines: lines)
        guard let header = lines.first else {
            throw ParseError.emptyFileAfterCleanup(fileUrl)
        }
        let orderedFieldTypes = try header.map { fieldName -> FieldType in
            guard let type = fieldTypeMapping[fieldName] else {
                throw ParseError.unknownFieldName(fieldName, fileUrl)
            }
            return type
        }
        for issueLine in linesWithIssuesAfterSequentialLineRepair {
            repairLinesWithMoreColumnsBasedOnExpectedFields(
                forLine: &lines[issueLine.lineIndex],
                targetColumnCount: issueLine.expectedColumnCount,
                expectedFieldTypes: orderedFieldTypes,
                fileName: fileName,
                lineNumber: issueLine.lineIndex)
        }

        // Step 4: Report any lines still incorrect after both repair passes
        let remainingIssues = findLinesWithIncorrectElementCount(fromLines: lines)
        if !remainingIssues.isEmpty {
            print("linesWithIssuesAfterLongLineRepair: \(remainingIssues)")
        }
        return remainingIssues
    }

    /// Reads all CSV files from a directory, applies both short-line and long-line repairs concurrently, and returns any unresolved issues.
    ///
    /// Files are enumerated from the given directory (skipping hidden files), filtered by the
    /// `fileFilter` closure, then processed in parallel. For each file, the method:
    /// 1. Parses the file content using ISO Latin 1 encoding.
    /// 2. Merges consecutive short lines.
    /// 3. Repairs long lines using field-type validation from the `fileToFieldType` mapping.
    ///
    /// - Parameters:
    ///   - directory: The directory URL to scan for CSV files.
    ///   - fileFilter: A closure that returns `true` for files that should be processed.
    ///   - fileToFieldType: A closure mapping a file URL to its column-name-to-``FieldType`` dictionary.
    ///     Return `nil` for files that should not have field-type-based repair applied.
    /// - Throws: ``ParseError`` if file data cannot be decoded. Consider making this a typed throw
    ///   (`throws(ParseError)`) in a future version, once `fatalError` calls are replaced with thrown errors.
    /// - Returns: An array of ``FileIssues``, one per file, listing any lines still incorrect after repair.
    public static func correctErrorsIn(directory: URL, fileFilter: (URL) -> Bool, fileToFieldType: @escaping (URL) -> [String : FieldType]?) async throws -> [FileIssues] {
        guard let enumerator = FileManager.default
            .enumerator(at: directory,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles) else {
            throw ParseError.directoryEnumerationFailed(directory)
        }
        guard let items = enumerator.allObjects as? [URL] else {
            throw ParseError.directoryEnumerationFailed(directory)
        }
        let csvItems = items.filter { $0.lastPathComponent.hasSuffix("csv") }
            .filter { fileFilter($0) }
        print("csvItems.count: \(csvItems.count)")
        let fileErrors = try await csvItems
            .concurrentMap { csvFile -> FileIssues in
                guard let mappingDict = fileToFieldType(csvFile) else {
                    throw ParseError.missingFieldTypeMapping(csvFile)
                }
                return try await Task {
                    let fileString = try String(contentsOf: csvFile, encoding: .isoLatin1)
                    var lines = CSVErrorRepair.getLines(fromString: fileString)
                    let remainingIssues = try CSVErrorRepair.repairLines(
                        &lines,
                        fieldTypeMapping: mappingDict,
                        fileName: csvFile.lastPathComponent,
                        fileUrl: csvFile)
                    return FileIssues(fileUrl: csvFile, issues: remainingIssues)
                }.value
            }
        return fileErrors
    }

    /// Applies both short-line and long-line repairs to pre-loaded CSV file data concurrently, and returns any unresolved issues.
    ///
    /// Same repair pipeline as ``correctErrorsIn(directory:fileFilter:fileToFieldType:)`` but
    /// operates on an array of `(URL, Data)` tuples instead of reading from disk. Only entries
    /// whose URL ends with `"csv"` are processed.
    ///
    /// - Parameters:
    ///   - files: An array of `(URL, Data)` tuples representing CSV files.
    ///   - fileToFieldType: A closure mapping a file URL to its column-name-to-``FieldType`` dictionary.
    /// - Throws: ``ParseError/failedToGetStringFromData`` if file data cannot be decoded. Consider making
    ///   this a typed throw (`throws(ParseError)`) in a future version.
    /// - Returns: An array of ``FileIssues``, one per file, listing any lines still incorrect after repair.
    public static func correctErrorsIn(files: [(URL, Data)], fileToFieldType: @escaping (URL) -> [String : FieldType]?) async throws -> [FileIssues] {
        let csvData = files.filter { $0.0.lastPathComponent.hasSuffix("csv") }
        print("csvItems.count: \(csvData.count)")
        let fileErrors = try await csvData
            .concurrentMap { csvFile -> FileIssues in
                guard let mappingDict = fileToFieldType(csvFile.0) else {
                    throw ParseError.missingFieldTypeMapping(csvFile.0)
                }
                return try await Task {
                    guard let fileString = String(data: csvFile.1, encoding: .isoLatin1) else {
                        throw ParseError.failedToGetStringFromData
                    }
                    var lines = CSVErrorRepair.getLines(fromString: fileString)
                    let remainingIssues = try CSVErrorRepair.repairLines(
                        &lines,
                        fieldTypeMapping: mappingDict,
                        fileName: csvFile.0.lastPathComponent,
                        fileUrl: csvFile.0)
                    return FileIssues(fileUrl: csvFile.0, issues: remainingIssues)
                }.value
            }
        return fileErrors
    }

    #if os(macOS)
//    @available(macOS 10.13, *)
//    public static func correctErrorsIn(_ lines: inout [[String]], forUrl url: URL, fieldTypes: [String : FieldType]) throws -> FileIssues {
//        return autoreleasepool {
//            let linesWithIssues = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)
//            if linesWithIssues.count > 0 {
//                for issueLine in linesWithIssues {
//                    CSVErrorRepair.repairSequentialShortLines(lines: &lines,
//                                                  firstLineIndex: issueLine.lineIndex,
//                                                  targetColumnCount: issueLine.expectedColumnCount)
//                }
//                lines.removeAll{ $0.count == 0 } // prevents issues with lines that end with /r
//                lines.removeAll { $0.count == 1 && $0.first!.isEmpty } // prevents issues with lines that end with /r
//                let linesWithIssuesAfterSequentialLineRepair = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)
//                let fieldTypes = lines.first!.map { fieldName in
//                    guard let type = fieldTypes[fieldName] else {
//                        fatalError("failed to get field type for \(fieldName)")
//                    }
//                    return type
//                }
//                for issueLine in linesWithIssuesAfterSequentialLineRepair {
//                    CSVErrorRepair.repairLinesWithMoreColumnsBasedOnExpectedFields(forLine: &lines[issueLine.lineIndex],
//                                                                                    targetColumnCount: issueLine.expectedColumnCount,
//                                                                                    expectedFieldTypes: fieldTypes,
//                                                                                    fileName: url.lastPathComponent,
//                                                                                    lineNumber: issueLine.lineIndex)
//                }
//                let linesWithIssuesAfterLongLineRepair = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)
//                if !linesWithIssuesAfterLongLineRepair.isEmpty {
//                    print("linesWithIssuesAfterLongLineRepair: \(linesWithIssuesAfterLongLineRepair)")
//                }
//                return FileIssues(fileUrl: url, issues: linesWithIssuesAfterLongLineRepair)
//            }else{
//                return FileIssues(fileUrl: url, issues: linesWithIssues)
//            }
//        }
//    }
    #endif

    /// Applies both short-line and long-line repairs to a single file's parsed lines and returns the corrected result.
    ///
    /// This is the primary single-file repair method. It:
    /// 1. Merges consecutive short lines to fix rows split by embedded newlines.
    /// 2. Removes empty lines left behind by the merge process.
    /// 3. Uses field-type validation to repair lines that have too many columns.
    ///
    /// Unlike the batch methods, this returns the repaired lines along with any unresolved issues,
    /// allowing you to inspect or further process the result.
    ///
    /// - Parameters:
    ///   - inputLines: The parsed CSV lines to repair. Not modified — a copy is made internally.
    ///   - url: The source file URL, used for diagnostic output and to populate ``FileIssues/fileUrl``.
    ///   - fieldTypes: A dictionary mapping column header names to their expected ``FieldType``.
    /// - Throws: ``ParseError/emptyFileAfterCleanup(_:)`` if all lines are removed during cleanup.
    ///   ``ParseError/unknownFieldName(_:_:)`` if a header column has no entry in the `fieldTypes` dictionary.
    /// - Returns: A tuple of the repaired line arrays and a ``FileIssues`` listing any lines that remain incorrect.
    public static func correctErrorsIn(_ inputLines: [[String]], forUrl url: URL, fieldTypes: [String : FieldType]) async throws -> (resultLines: [[String]], issues: FileIssues) {
        return try await Task {
            var lines = inputLines
            let remainingIssues = try CSVErrorRepair.repairLines(
                &lines,
                fieldTypeMapping: fieldTypes,
                fileName: url.lastPathComponent,
                fileUrl: url)
            return (lines, FileIssues(fileUrl: url, issues: remainingIssues))
        }.value
    }
}

/// Errors that can occur during CSV parsing and repair.
public enum ParseError: Error {
    /// The validated index array was unexpectedly empty when attempting to retrieve its last element.
    case failedToGetLastItemFromValidatedIndicyArray
    /// The provided `Data` could not be converted to a `String` using the specified encoding.
    case failedToGetStringFromData
    /// The directory enumerator returned unexpected content or was nil.
    case directoryEnumerationFailed(URL)
    /// The `fileToFieldType` closure returned `nil` for a file that needed field-type repair.
    case missingFieldTypeMapping(URL)
    /// After cleanup the file had no lines remaining (no header row to derive field types from).
    case emptyFileAfterCleanup(URL)
    /// A column header in the CSV had no corresponding entry in the field-type dictionary.
    case unknownFieldName(String, URL)
}
