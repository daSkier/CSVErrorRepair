//
//  GetLinesFastPathEquivalenceTests.swift
//
//  Equivalence proof for the byte-level `getLines(fromData:)` fast path
//  (ISO-Latin-1 + single-byte column delimiter): for every input class, the
//  fast path must produce EXACTLY the output of decoding the bytes and running
//  the legacy string path (`getLines(fromString:)`). If these two ever diverge,
//  the fast path is wrong — the string path is the semantic reference.
//
//  Also pins the fallback: multi-byte delimiters and non-Latin-1 encodings must
//  still route through the string path (verified indirectly: a .utf8 call with
//  invalid bytes must still throw, which the fast path never does).
//

import XCTest
@testable import CSVErrorRepair

final class GetLinesFastPathEquivalenceTests: XCTestCase {

    /// The reference implementation: decode as Latin-1, run the string path.
    private func referenceParse(_ data: Data, columnDelimeter: String = "\t") -> [[String]] {
        let string = String(data: data, encoding: .isoLatin1)!
        return CSVErrorRepair.getLines(fromString: string, columnDelimeter: columnDelimeter)
    }

    /// Assert fast path == string path for the given raw bytes.
    private func assertEquivalent(_ bytes: [UInt8], columnDelimeter: String = "\t",
                                  file: StaticString = #filePath, line: UInt = #line) throws {
        let data = Data(bytes)
        let fast = try CSVErrorRepair.getLines(fromData: data, columnDelimeter: columnDelimeter, encoding: .isoLatin1)
        let reference = referenceParse(data, columnDelimeter: columnDelimeter)
        XCTAssertEqual(fast, reference, file: file, line: line)
    }

    private func assertEquivalent(_ string: String, columnDelimeter: String = "\t",
                                  file: StaticString = #filePath, line: UInt = #line) throws {
        try assertEquivalent(Array(string.unicodeScalars.map { UInt8($0.value) }),
                             columnDelimeter: columnDelimeter, file: file, line: line)
    }

    // MARK: - Line-ending permutations

    func testLFOnly() throws {
        try assertEquivalent("a\tb\nc\td\n")
    }

    func testCRLFOnly() throws {
        try assertEquivalent("a\tb\r\nc\td\r\n")
    }

    func testLoneCROnly() throws {
        try assertEquivalent("a\tb\rc\td\r")
    }

    func testMixedEndingsInOneFile() throws {
        try assertEquivalent("a\tb\r\nc\td\ne\tf\rg\th")
    }

    /// CR followed by CRLF ("\r\r\n") — the CR ends a row, the CRLF ends the next
    /// (empty) row. The string path normalizes this to "\n\n"; the fast path must
    /// match (a lone CR does NOT pair with a CR two bytes later).
    func testCRThenCRLF() throws {
        try assertEquivalent("a\r\r\nb")
    }

    /// LF followed by CR ("\n\r") is TWO separators (an empty row between).
    func testLFThenCR() throws {
        try assertEquivalent("a\n\rb")
    }

    func testConsecutiveCRLFs() throws {
        try assertEquivalent("a\r\n\r\nb")
    }

    // MARK: - Empty / degenerate inputs

    func testEmptyData() throws {
        try assertEquivalent([])
    }

    func testSingleNewlineOnly() throws {
        try assertEquivalent("\n")
    }

    func testSingleCROnly() throws {
        try assertEquivalent("\r")
    }

    func testSingleCRLFOnly() throws {
        try assertEquivalent("\r\n")
    }

    func testNoTrailingNewline() throws {
        try assertEquivalent("a\tb\nc\td")
    }

    func testOnlyDelimiters() throws {
        try assertEquivalent("\t\t\t")
    }

    // MARK: - Cell-boundary permutations

    func testLeadingDelimiter() throws {
        try assertEquivalent("\ta\tb\n")
    }

    func testTrailingDelimiterProducesTrailingEmptyCell() throws {
        try assertEquivalent("a\tb\t\n")
    }

    func testConsecutiveDelimitersProduceEmptyMiddleCells() throws {
        try assertEquivalent("a\t\t\tb\n")
    }

    func testRowOfOnlyEmptyCells() throws {
        try assertEquivalent("\t\t\na\tb\tc\n")
    }

    // MARK: - Latin-1 high bytes (accented names — the FIS athlete case)

    /// Bytes ≥ 0x80 are Latin-1 scalars U+0080–U+00FF; the fast path transcodes
    /// them to UTF-8. é=0xE9, ü=0xFC, Å=0xC5, ß=0xDF.
    func testHighBytesDecodeAsLatin1Scalars() throws {
        try assertEquivalent([0x4A, 0xE9, 0x72, 0x09, 0x4D, 0xFC, 0x6C, 0x6C, 0x65, 0x72, 0x0A,
                              0xC5, 0x73, 0x09, 0x53, 0x74, 0x72, 0x61, 0xDF, 0x65, 0x0A])
    }

    /// A cell that is ONLY high bytes.
    func testAllHighByteCell() throws {
        try assertEquivalent([0xE9, 0xFC, 0xC5, 0x09, 0x61, 0x0A])
    }

    /// Every possible byte value (except the delimiters themselves) round-trips
    /// identically through both paths — the exhaustive Latin-1 decode check.
    func testAllByteValuesRoundTrip() throws {
        var bytes: [UInt8] = []
        for value in UInt8.min...UInt8.max where value != 0x09 && value != 0x0A && value != 0x0D {
            bytes.append(value)
            bytes.append(0x09)
        }
        bytes.append(0x0A)
        try assertEquivalent(bytes)
    }

    // MARK: - Alternate single-byte delimiter

    func testCommaDelimiter() throws {
        try assertEquivalent("a,b\r\nc,d\r\n", columnDelimeter: ",")
    }

    // MARK: - Fallback routing

    /// Multi-byte column delimiter must fall back to the string path and still work.
    func testMultiByteDelimiterFallsBackToStringPath() throws {
        let data = "a::b\nc::d".data(using: .isoLatin1)!
        let lines = try CSVErrorRepair.getLines(fromData: data, columnDelimeter: "::", encoding: .isoLatin1)
        XCTAssertEqual(lines, [["a", "b"], ["c", "d"]])
    }

    /// Invalid-UTF-8 bytes with encoding .utf8 must STILL throw — proving the
    /// fast path (which never fails) is not applied to non-Latin-1 encodings.
    func testUTF8EncodingStillThrowsOnInvalidBytes() {
        let invalidUTF8 = Data([0x61, 0xFF, 0xFE, 0x62])
        XCTAssertThrowsError(try CSVErrorRepair.getLines(fromData: invalidUTF8, encoding: .utf8))
    }

    // MARK: - Structured file shape (header + data + trailing newline)

    func testTypicalFISShape() throws {
        try assertEquivalent("Recid\tCompetitorid\tName\r\n1\t100\tJos\u{E9}\r\n2\t101\tM\u{FC}ller\r\n")
    }

    /// Randomized fuzz: byte soup drawn from delimiters, ASCII, and high bytes.
    /// Seeded RNG so failures are reproducible.
    func testFuzzedEquivalence() throws {
        var state: UInt64 = 0x5EED_CAFE_F00D_D00D
        func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
        let alphabet: [UInt8] = [0x09, 0x0A, 0x0D, 0x41, 0x42, 0x61, 0x7A, 0x30, 0xE9, 0xFC, 0x20, 0x2E]
        for _ in 0..<200 {
            let length = Int(next() % 64)
            var bytes: [UInt8] = []
            bytes.reserveCapacity(length)
            for _ in 0..<length {
                bytes.append(alphabet[Int(next() % UInt64(alphabet.count))])
            }
            try assertEquivalent(bytes)
        }
    }
}
