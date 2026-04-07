//
//  PerformanceBenchmarkTests.swift
//
//
//  Benchmarks for issues 9-11, 13-14 from IMPROVEMENTS.md.
//  Run on main before changes to establish baseline, then again after.
//

import XCTest
@testable import CSVErrorRepair

// MARK: - Synthetic Data Generators

private enum BenchmarkData {

    /// Generates a large CSV string: `rowCount` rows × `colCount` tab-separated columns.
    /// Includes a header row. Some cells contain quotes to exercise the checkForQuotes path.
    static func largeCSV(rowCount: Int = 10_000, colCount: Int = 20) -> String {
        let header = (0..<colCount).map { "Col\($0)" }.joined(separator: "\t")
        let rows = (0..<rowCount).map { rowIdx in
            (0..<colCount).map { colIdx in
                if colIdx == 0 {
                    return "\(rowIdx)"
                } else if colIdx % 7 == 0 {
                    return "\"quoted value \(rowIdx)\""
                } else {
                    return "value_\(rowIdx)_\(colIdx)"
                }
            }.joined(separator: "\t")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    /// Generates field types and a line with one extra column to benchmark the repair algorithm.
    /// Uses a mix of field types to exercise the full validation path.
    static func repairBenchmarkData(colCount: Int = 80) -> (fieldTypes: [FieldType], line: [String]) {
        var fieldTypes: [FieldType] = []
        var line: [String] = []

        for i in 0..<colCount {
            switch i % 6 {
            case 0:
                fieldTypes.append(.integer(nullable: false, expectedValue: nil, expectedLength: nil))
                line.append("\(i * 100)")
            case 1:
                fieldTypes.append(.float(nullable: true))
                line.append("\(Double(i) * 1.5)")
            case 2:
                fieldTypes.append(.string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil))
                line.append("USA")
            case 3:
                fieldTypes.append(.unknownString(nullable: true))
                line.append("Name_\(i)")
            case 4:
                fieldTypes.append(.date(nullable: true))
                line.append("2023-09-04")
            case 5:
                fieldTypes.append(.empty)
                line.append("")
            default:
                break
            }
        }

        // Insert an extra column in the middle to create a line that needs repair
        let insertPoint = colCount / 2
        line.insert("extra_column", at: insertPoint)

        return (fieldTypes, line)
    }
}

// MARK: - Issue 13: getLines performance

final class GetLinesPerformanceTests: XCTestCase {

    private let largeCSV = BenchmarkData.largeCSV(rowCount: 100_000, colCount: 40)

    func testGetLinesPerformance() {
        measure {
            let _ = CSVErrorRepair.getLines(fromString: largeCSV)
        }
    }
}

// MARK: - Issue 14: convertToString performance

final class ConvertToStringPerformanceTests: XCTestCase {

    private let parsedLines: [[String]] = {
        CSVErrorRepair.getLines(fromString: BenchmarkData.largeCSV(rowCount: 100_000, colCount: 40))
    }()

    /// Default path (checkForQuotes: false) — this is the hot path being optimized.
    func testConvertToStringPerformance() {
        measure {
            let _ = CSVErrorRepair.convertToString(lines: parsedLines)
        }
    }

    /// With quote stripping enabled (control — should be roughly the same before/after).
    func testConvertToStringWithQuotesPerformance() {
        measure {
            let _ = CSVErrorRepair.convertToString(lines: parsedLines, checkForQuotes: true)
        }
    }
}

// MARK: - Issues 9, 10, 11: repairLinesWithMoreColumnsBasedOnExpectedFields performance

final class RepairLongLinePerformanceTests: XCTestCase {

    private let benchmarkData = BenchmarkData.repairBenchmarkData(colCount: 80)

    /// Benchmarks the full repair path: validate → mergedLastIndices → merge candidates → pick best.
    func testRepairLongLinePerformance() {
        let fieldTypes = benchmarkData.fieldTypes
        let targetColumnCount = fieldTypes.count

        measure {
            for _ in 0..<500 {
                var line = benchmarkData.line
                CSVErrorRepair.repairLinesWithMoreColumnsBasedOnExpectedFields(
                    forLine: &line,
                    targetColumnCount: targetColumnCount,
                    expectedFieldTypes: fieldTypes,
                    fileName: "benchmark",
                    lineNumber: 0)
            }
        }
    }
}
