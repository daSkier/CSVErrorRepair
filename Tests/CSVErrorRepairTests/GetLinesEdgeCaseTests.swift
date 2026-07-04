//
//  GetLinesEdgeCaseTests.swift
//
//  Coverage for uncontrolled / malformed CSV inputs beyond the #80 line-ending
//  cases: empty & degenerate inputs, mid-file blank lines (and how they flow
//  through the short-line repair), the fromData encoding-failure path, pure
//  classic-Mac (lone-CR) line endings, and delimiter edges.
//
//  These pin the library's behavior for the FIS domain (tab-delimited, unquoted,
//  ISO-Latin1). Note `getLines` is intentionally NOT quote-aware — see its doc
//  comment — so quoted fields containing delimiters/newlines are out of scope.
//

import XCTest
@testable import CSVErrorRepair

// MARK: - #1 Empty & degenerate inputs

final class GetLinesDegenerateInputTests: XCTestCase {

    /// An empty string yields a single row with a single empty cell (not a crash, not []).
    func testEmptyStringProducesSingleEmptyRow() {
        XCTAssertEqual(CSVErrorRepair.getLines(fromString: ""), [[""]])
    }

    /// Empty `Data` decodes to the empty string under ISO-Latin1 (which maps every
    /// byte), so it does NOT throw — it yields the same single empty row.
    func testEmptyDataDoesNotThrowAndProducesSingleEmptyRow() throws {
        let lines = try CSVErrorRepair.getLines(fromData: Data(), encoding: .isoLatin1)
        XCTAssertEqual(lines, [[""]])
    }

    /// A header-only file is a single well-formed row; it is the reference row, so
    /// it reports zero column-count errors.
    func testHeaderOnlyFileHasNoErrors() {
        let csv = "A\tB\tC"
        XCTAssertEqual(CSVErrorRepair.getLines(fromString: csv), [["A", "B", "C"]])
        XCTAssertEqual(CSVErrorRepair.findLinesWithErrors(fromString: csv).count, 0)
    }

    /// A single data cell round-trips as one row, one cell.
    func testSingleCellSingleRow() {
        XCTAssertEqual(CSVErrorRepair.getLines(fromString: "hello"), [["hello"]])
    }
}

// MARK: - #2 Mid-file blank lines and the short-line repair interaction

final class GetLinesBlankLineTests: XCTestCase {

    /// Structural: a blank line in the middle of the file becomes a `[""]` row.
    func testMidFileBlankLineBecomesEmptyRow() {
        let lines = CSVErrorRepair.getLines(fromString: "A\tB\tC\n1\t2\t3\n\n4\t5\t6")
        XCTAssertEqual(lines, [["A", "B", "C"], ["1", "2", "3"], [""], ["4", "5", "6"]])
    }

    /// Asymmetry worth documenting: a *trailing* blank line is skipped by the
    /// error detector, but a *mid-file* blank line IS flagged (as a short line),
    /// because the skip only applies to the last line.
    func testMidFileBlankLineIsFlaggedUnlikeTrailingBlank() {
        // trailing blank — skipped
        XCTAssertEqual(CSVErrorRepair.findLinesWithErrors(fromString: "A\tB\tC\n1\t2\t3\n").count, 0)
        // mid-file blank — flagged at its index
        let midErrors = CSVErrorRepair.findLinesWithErrors(fromString: "A\tB\tC\n1\t2\t3\n\n4\t5\t6")
        XCTAssertEqual(midErrors.count, 1)
        XCTAssertEqual(midErrors.first?.lineIndex, 2)
    }

    /// Behavior guarantee: a lone mid-file blank line is repaired NON-destructively.
    /// It is not merged into a neighbor (the merge routine only fires for
    /// consecutive short lines); the cleanup simply drops the empty row, so every
    /// data row is preserved in order.
    func testLoneMidFileBlankLineIsRemovedAndDataPreserved() {
        var lines = CSVErrorRepair.getLines(fromString: "A\tB\tC\n1\t2\t3\n\n4\t5\t6")
        CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
        XCTAssertEqual(lines, [["A", "B", "C"], ["1", "2", "3"], ["4", "5", "6"]])
    }

    /// Multiple consecutive mid-file blank lines are likewise cleaned away with the
    /// data rows intact.
    func testMultipleConsecutiveBlankLinesRemovedDataPreserved() {
        var lines = CSVErrorRepair.getLines(fromString: "A\tB\tC\n1\t2\t3\n\n\n4\t5\t6")
        CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
        XCTAssertEqual(lines, [["A", "B", "C"], ["1", "2", "3"], ["4", "5", "6"]])
    }

    /// Characterization: a whitespace-only line is NOT treated as blank — its cell
    /// is non-empty, so it is neither skipped nor dropped by the empty-line cleanup,
    /// and remains flagged as a short line. (Documents that "blank" means truly
    /// empty, not whitespace.)
    func testWhitespaceOnlyLineIsNotTreatedAsBlank() {
        let errors = CSVErrorRepair.findLinesWithErrors(fromString: "A\tB\tC\n   \n1\t2\t3")
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors.first?.lineIndex, 1)
    }
}

// MARK: - #3 fromData encoding-failure path

final class GetLinesEncodingFailureTests: XCTestCase {

    /// Bytes that are not decodable in the requested encoding cause `getLines(fromData:)`
    /// to throw `ParseError.failedToGetStringFromData` rather than returning garbage.
    /// (0xFF is never a valid UTF-8 byte.)
    func testGetLinesFromDataThrowsOnUndecodableBytes() {
        let invalidUTF8 = Data([0xFF, 0xFE, 0xFF])
        XCTAssertThrowsError(try CSVErrorRepair.getLines(fromData: invalidUTF8, encoding: .utf8)) { error in
            guard case ParseError.failedToGetStringFromData = error else {
                return XCTFail("expected ParseError.failedToGetStringFromData, got \(error)")
            }
        }
    }

    /// The same bytes decode fine under ISO-Latin1 (which maps all 256 byte values),
    /// confirming the throw is encoding-specific, not data-specific.
    func testSameBytesDecodeUnderISOLatin1() throws {
        let bytes = Data([0xFF, 0xFE, 0xFF])
        XCTAssertNoThrow(try CSVErrorRepair.getLines(fromData: bytes, encoding: .isoLatin1))
    }
}

// MARK: - #4 Pure classic-Mac (lone-CR) line endings + delimiter edges

final class GetLinesCarriageReturnAndDelimiterTests: XCTestCase {

    /// A file delimited entirely by lone CRs (classic Mac) splits into rows just
    /// like LF/CRLF, with no CR left in any cell.
    func testPureLoneCRDelimitedFileSplitsCorrectly() {
        let cr = "A\tB\tC\r1\t2\t3\r4\t5\t6"
        let lines = CSVErrorRepair.getLines(fromString: cr)
        XCTAssertEqual(lines, [["A", "B", "C"], ["1", "2", "3"], ["4", "5", "6"]])
        for row in lines { for cell in row { XCTAssertFalse(cell.contains("\r")) } }
    }

    /// A trailing column delimiter yields a trailing empty cell (column count grows).
    func testTrailingDelimiterProducesTrailingEmptyCell() {
        XCTAssertEqual(CSVErrorRepair.getLines(fromString: "A\tB\t"), [["A", "B", ""]])
    }

    /// Consecutive column delimiters yield an empty cell in the middle.
    func testConsecutiveDelimitersProduceEmptyMiddleCell() {
        XCTAssertEqual(CSVErrorRepair.getLines(fromString: "A\t\tC"), [["A", "", "C"]])
    }
}
