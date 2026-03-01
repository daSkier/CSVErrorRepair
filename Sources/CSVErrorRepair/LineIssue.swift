//
//  LineIssue.swift
//
//
//  Created by Justin on 11/12/23.
//

/// Describes a single CSV line that has an incorrect number of columns.
///
/// Returned by ``CSVErrorRepair/findLinesWithIncorrectElementCount(fromLines:)`` and
/// ``CSVErrorRepair/findLinesWithErrors(fromString:)``. A line with fewer columns than
/// expected is a "short line" (likely split by an embedded newline), while a line with
/// more columns than expected is a "long line" (likely containing an embedded delimiter).
public struct LineIssue: Sendable {
    /// The zero-based index of the problematic line in the parsed line array.
    var lineIndex: Int
    /// The actual number of columns found on this line.
    var columnCount: Int
    /// The expected number of columns, derived from the header (first) row.
    var expectedColumnCount: Int
}
