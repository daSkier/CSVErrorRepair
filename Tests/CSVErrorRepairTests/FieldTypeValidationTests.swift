//
//  FieldTypeValidationTests.swift
//
//
//  Tests for FieldType.validate(inputString:) covering all field types
//  and the bug fixes for issues 1-3 from IMPROVEMENTS.md.
//

import XCTest
@testable import CSVErrorRepair

final class FieldTypeValidationTests: XCTestCase {

    // MARK: - Integer

    func testIntegerValid() {
        let field = FieldType.integer(nullable: false, expectedValue: nil, expectedLength: nil)
        XCTAssertEqual(field.validate(inputString: "42"), .valid)
        XCTAssertEqual(field.validate(inputString: "0"), .valid)
        XCTAssertEqual(field.validate(inputString: "-7"), .valid)
    }

    func testIntegerInvalid() {
        let field = FieldType.integer(nullable: false, expectedValue: nil, expectedLength: nil)
        XCTAssertEqual(field.validate(inputString: "abc"), .invalid)
        XCTAssertEqual(field.validate(inputString: "3.14"), .invalid)
    }

    func testIntegerNullable() {
        let nullable = FieldType.integer(nullable: true, expectedValue: nil, expectedLength: nil)
        XCTAssertEqual(nullable.validate(inputString: ""), .null)

        let nonNullable = FieldType.integer(nullable: false, expectedValue: nil, expectedLength: nil)
        XCTAssertEqual(nonNullable.validate(inputString: ""), .invalid)
    }

    func testIntegerExpectedValue() {
        let field = FieldType.integer(nullable: false, expectedValue: 0, expectedLength: nil)
        XCTAssertEqual(field.validate(inputString: "0"), .valid)
        XCTAssertEqual(field.validate(inputString: "1"), .invalid)
        XCTAssertEqual(field.validate(inputString: "abc"), .invalid)
    }

    func testIntegerExpectedLength() {
        let field = FieldType.integer(nullable: false, expectedValue: nil, expectedLength: 4)
        XCTAssertEqual(field.validate(inputString: "2019"), .valid)
        XCTAssertEqual(field.validate(inputString: "19"), .invalid)
        XCTAssertEqual(field.validate(inputString: "abcd"), .invalid)
    }

    // MARK: - Float

    func testFloatValid() {
        let field = FieldType.float(nullable: false)
        XCTAssertEqual(field.validate(inputString: "3.14"), .valid)
        XCTAssertEqual(field.validate(inputString: "0"), .valid)
        XCTAssertEqual(field.validate(inputString: "-12.5"), .valid)
    }

    func testFloatInvalid() {
        let field = FieldType.float(nullable: false)
        XCTAssertEqual(field.validate(inputString: "abc"), .invalid)
    }

    func testFloatNullable() {
        let nullable = FieldType.float(nullable: true)
        XCTAssertEqual(nullable.validate(inputString: ""), .null)

        let nonNullable = FieldType.float(nullable: false)
        XCTAssertEqual(nonNullable.validate(inputString: ""), .invalid)
    }

    // MARK: - String (Issue 2 & 3 fixes)

    func testStringWithExpectedLengthOnly() {
        let field = FieldType.string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil)
        XCTAssertEqual(field.validate(inputString: "USA"), .valid)
        XCTAssertEqual(field.validate(inputString: "US"), .invalid)
        XCTAssertEqual(field.validate(inputString: "LONG"), .invalid)
    }

    func testStringWithStartsWithOnly() {
        let field = FieldType.string(nullable: false, expectedLength: nil, startsWith: "http", contains: nil)
        XCTAssertEqual(field.validate(inputString: "https://example.com"), .valid)
        XCTAssertEqual(field.validate(inputString: "ftp://example.com"), .invalid)
    }

    func testStringWithContainsOnly() {
        let field = FieldType.string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@")
        XCTAssertEqual(field.validate(inputString: "user@example.com"), .valid)
        XCTAssertEqual(field.validate(inputString: "no-at-sign"), .invalid)
    }

    func testStringWithStartsWithAndContains() {
        let field = FieldType.string(nullable: false, expectedLength: nil, startsWith: "http", contains: ".com")
        XCTAssertEqual(field.validate(inputString: "https://example.com"), .valid)
        XCTAssertEqual(field.validate(inputString: "https://example.org"), .invalid)
        XCTAssertEqual(field.validate(inputString: "ftp://example.com"), .invalid)
    }

    /// Issue 2: `contains` was ignored when `expectedLength` was set.
    func testStringWithExpectedLengthAndContains() {
        let field = FieldType.string(nullable: false, expectedLength: 5, startsWith: nil, contains: "abc")
        XCTAssertEqual(field.validate(inputString: "xabcx"), .valid)   // length 5 and contains "abc"
        XCTAssertEqual(field.validate(inputString: "xxxxx"), .invalid) // length 5 but no "abc"
        XCTAssertEqual(field.validate(inputString: "abc"), .invalid)   // contains "abc" but wrong length
    }

    /// Issue 2: All three constraints together.
    func testStringWithAllConstraints() {
        let field = FieldType.string(nullable: false, expectedLength: 10, startsWith: "US", contains: "@")
        XCTAssertEqual(field.validate(inputString: "US-test@__"), .valid)  // length 10, starts with "US", contains "@"
        XCTAssertEqual(field.validate(inputString: "US-testXXX"), .invalid) // no "@"
        XCTAssertEqual(field.validate(inputString: "UK-test@__"), .invalid) // wrong prefix
        XCTAssertEqual(field.validate(inputString: "US@"), .invalid)        // wrong length
    }

    /// Issue 2: `expectedLength` + `startsWith` combination.
    func testStringWithExpectedLengthAndStartsWith() {
        let field = FieldType.string(nullable: false, expectedLength: 3, startsWith: "U", contains: nil)
        XCTAssertEqual(field.validate(inputString: "USA"), .valid)
        XCTAssertEqual(field.validate(inputString: "GER"), .invalid)  // wrong prefix
        XCTAssertEqual(field.validate(inputString: "US"), .invalid)   // wrong length
    }

    /// Issue 3: String with no constraints should accept any non-empty string.
    func testStringWithNoConstraints() {
        let field = FieldType.string(nullable: false, expectedLength: nil, startsWith: nil, contains: nil)
        XCTAssertEqual(field.validate(inputString: "anything"), .valid)
        XCTAssertEqual(field.validate(inputString: "x"), .valid)
        XCTAssertEqual(field.validate(inputString: ""), .invalid) // non-nullable
    }

    /// Issue 3: Nullable string with no constraints.
    func testStringNullableNoConstraints() {
        let field = FieldType.string(nullable: true, expectedLength: nil, startsWith: nil, contains: nil)
        XCTAssertEqual(field.validate(inputString: "anything"), .valid)
        XCTAssertEqual(field.validate(inputString: ""), .null)
    }

    func testStringNullable() {
        let nullable = FieldType.string(nullable: true, expectedLength: 3, startsWith: nil, contains: nil)
        XCTAssertEqual(nullable.validate(inputString: ""), .null)

        let nonNullable = FieldType.string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil)
        XCTAssertEqual(nonNullable.validate(inputString: ""), .invalid)
    }

    // MARK: - Unknown String

    func testUnknownStringValid() {
        let field = FieldType.unknownString(nullable: false)
        XCTAssertEqual(field.validate(inputString: "anything"), .unknownString)
    }

    func testUnknownStringNullable() {
        let nullable = FieldType.unknownString(nullable: true)
        XCTAssertEqual(nullable.validate(inputString: ""), .null)

        let nonNullable = FieldType.unknownString(nullable: false)
        XCTAssertEqual(nonNullable.validate(inputString: ""), .invalid)
    }

    // MARK: - Date (Issue 1 fix)

    func testDateValid() {
        let field = FieldType.date(nullable: false)
        XCTAssertEqual(field.validate(inputString: "2023-09-04"), .valid)
        XCTAssertEqual(field.validate(inputString: "2019-03-14"), .valid)
    }

    func testDateInvalid() {
        let field = FieldType.date(nullable: false)
        XCTAssertEqual(field.validate(inputString: "not-a-date"), .invalid)
        XCTAssertEqual(field.validate(inputString: "09/04/2023"), .invalid)
        XCTAssertEqual(field.validate(inputString: "2023-09-04 12:00:00"), .invalid)
    }

    /// Issue 1: Empty string on nullable date should return `.null`, not `.invalid`.
    func testDateNullableEmpty() {
        let nullable = FieldType.date(nullable: true)
        XCTAssertEqual(nullable.validate(inputString: ""), .null)
    }

    /// Issue 1: Empty string on non-nullable date should return `.invalid`.
    func testDateNonNullableEmpty() {
        let nonNullable = FieldType.date(nullable: false)
        XCTAssertEqual(nonNullable.validate(inputString: ""), .invalid)
    }

    /// Issue 1: Non-empty values should validate normally regardless of nullable.
    func testDateNullableWithValue() {
        let nullable = FieldType.date(nullable: true)
        XCTAssertEqual(nullable.validate(inputString: "2023-09-04"), .valid)
        XCTAssertEqual(nullable.validate(inputString: "not-a-date"), .invalid)
    }

    // MARK: - DateTime

    func testDateTimeValid() {
        let field = FieldType.dateTime
        XCTAssertEqual(field.validate(inputString: "2023-09-04 12:30:00"), .valid)
        XCTAssertEqual(field.validate(inputString: "2018-09-06 08:28:03"), .valid)
    }

    func testDateTimeInvalid() {
        let field = FieldType.dateTime
        XCTAssertEqual(field.validate(inputString: "2023-09-04"), .invalid)
        XCTAssertEqual(field.validate(inputString: "not-a-datetime"), .invalid)
        XCTAssertEqual(field.validate(inputString: ""), .invalid)
    }

    // MARK: - Empty

    func testEmptyValid() {
        let field = FieldType.empty
        XCTAssertEqual(field.validate(inputString: ""), .valid)
    }

    func testEmptyInvalid() {
        let field = FieldType.empty
        XCTAssertEqual(field.validate(inputString: "not empty"), .invalid)
    }
}
