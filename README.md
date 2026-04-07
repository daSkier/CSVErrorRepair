# CSVErrorRepair

A Swift library for detecting and automatically repairing common errors in CSV files.

CSV files sourced from real-world systems often contain errors introduced by user input: lines get split across multiple rows, or fields containing the delimiter character produce rows with too many columns. CSVErrorRepair provides tools to find these problems and fix them programmatically.

## Table of Contents

- [Installation](#installation)
- [Overview](#overview)
- [Parsing CSV Data](#parsing-csv-data)
- [Finding Errors](#finding-errors)
- [Repairing Short Lines](#repairing-short-lines)
- [Repairing Long Lines](#repairing-long-lines)
- [Applying All Repairs at Once](#applying-all-repairs-at-once)
- [Batch Processing](#batch-processing)
- [API Reference](#api-reference)
- [License](#license)

## Installation

Add CSVErrorRepair as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/daSkier/CSVErrorRepair.git", from: "0.1.0")
]
```

Then add it as a target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: ["CSVErrorRepair"]
)
```

**Requirements:**
- Swift 6.0+
- macOS 14+

## Overview

CSV errors handled by this library fall into two categories:

| Error Type | Symptom | Cause | Repair Strategy |
|---|---|---|---|
| **Short lines** | Row has fewer columns than expected | A newline character inside a field split one row into two | Merge consecutive short lines back together |
| **Long lines** | Row has more columns than expected | The delimiter character appeared inside a field value | Use field-type validation to identify which adjacent cells to merge |

The library operates on parsed line arrays (`[[String]]`) and applies repairs in-place using `inout` parameters to minimize memory allocations.

## Parsing CSV Data

Before finding or repairing errors, parse your CSV into a two-dimensional string array. CSVErrorRepair defaults to tab-delimited files with newline row separators, but both delimiters are configurable.

### From a String

```swift
import CSVErrorRepair

let fileString = try String(contentsOfFile: "/path/to/data.csv", encoding: .isoLatin1)
var lines = CSVErrorRepair.getLines(fromString: fileString)

// With custom delimiters (e.g. comma-separated, \r\n line endings)
var lines = CSVErrorRepair.getLines(
    fromString: fileString,
    lineDelimeter: "\r\n",
    columnDelimeter: ","
)
```

### From Data

```swift
let data = try Data(contentsOf: fileURL)
var lines = try CSVErrorRepair.getLines(
    fromData: data,
    encoding: .isoLatin1
)
```

### Converting Back

After repairing lines, convert back to a string or `Data` for writing to disk:

```swift
let repairedString = CSVErrorRepair.convertToString(lines: lines)

let repairedData = CSVErrorRepair.convertToData(
    lines: lines,
    encoding: .isoLatin1
)
```

## Finding Errors

Identify lines whose column count differs from the header row:

```swift
let issues = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)

for issue in issues {
    print("Line \(issue.lineIndex): has \(issue.columnCount) columns, expected \(issue.expectedColumnCount)")
}
```

There is also a convenience method that parses and scans in one step:

```swift
let issues = CSVErrorRepair.findLinesWithErrors(fromString: fileString)
```

Each returned `LineIssue` contains the line index, its actual column count, and the expected column count (derived from the first row).

## Repairing Short Lines

Short lines occur when a field contained a newline character, splitting one logical row across multiple physical lines. The repair strategy finds consecutive short lines whose combined column count fits within the expected width and merges them:

```swift
var lines = CSVErrorRepair.getLines(fromString: fileString)
CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
```

This is a convenience wrapper. For finer control, call `repairSequentialShortLines` directly on specific lines:

```swift
CSVErrorRepair.repairSequentialShortLines(
    lines: &lines,
    firstLineIndex: issueLineIndex,
    targetColumnCount: expectedColumnCount
)
```

## Repairing Long Lines

Long lines occur when a field value contained the column delimiter, causing one logical field to be split across multiple columns. Repairing these requires knowing what type of data each column should contain so the library can determine which adjacent cells to merge.

### Step 1: Define Field Types

Create a dictionary mapping each column header name to its expected `FieldType`:

```swift
let fieldNameToTypes: [String: FieldType] = [
    "id":        .integer(nullable: false, expectedValue: nil, expectedLength: nil),
    "code":      .integer(nullable: false, expectedValue: nil, expectedLength: 4),
    "country":   .string(nullable: false, expectedLength: 2, startsWith: nil, contains: nil),
    "name":      .unknownString(nullable: true),
    "startDate": .date(nullable: false),
    "endDate":   .date(nullable: false),
    "location":  .unknownString(nullable: true),
    "lastUpdate": .dateTime
]
```

Available field types:

| FieldType | Validates | Example |
|---|---|---|
| `.integer(nullable:expectedValue:expectedLength:)` | Parses as `Int`; optionally checks exact value or digit count | `.integer(nullable: false, expectedValue: nil, expectedLength: 4)` |
| `.float(nullable:)` | Parses as `Float` | `.float(nullable: true)` |
| `.string(nullable:expectedLength:startsWith:contains:)` | Checks length, prefix, or substring | `.string(nullable: false, expectedLength: 2, startsWith: "US", contains: nil)` |
| `.unknownString(nullable:)` | Accepts any non-empty string (flexible wildcard) | `.unknownString(nullable: true)` |
| `.date(nullable:)` | Matches format `yyyy-MM-dd` | `.date(nullable: false)` |
| `.dateTime` | Matches format `yyyy-MM-dd HH:mm:ss` | `.dateTime` |
| `.empty` | Must be an empty string | `.empty` |

### Step 2: Repair

```swift
// Get the ordered array of FieldTypes from the header row
let fieldTypes: [FieldType] = lines.first!.map { fieldNameToTypes[$0]! }

let issues = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)

for issue in issues where issue.columnCount > issue.expectedColumnCount {
    CSVErrorRepair.repairLinesWithMoreColumnsBasedOnExpectedFields(
        forLine: &lines[issue.lineIndex],
        expectedFieldTypes: fieldTypes,
        fileName: "data.csv",
        lineNumber: issue.lineIndex
    )
}
```

The repair works by validating fields from both ends of the line (forward and backward), finding where validation breaks down, and merging adjacent cells at the most likely split point.

## Applying All Repairs at Once

To run both short-line and long-line repairs in a single call, use the async `correctErrorsIn` method. It applies short-line merging first, then uses field-type validation to fix any remaining long lines:

```swift
let fieldNameToTypes: [String: FieldType] = [ /* ... */ ]

let fileString = try String(contentsOfFile: "/path/to/data.csv", encoding: .isoLatin1)
let lines = CSVErrorRepair.getLines(fromString: fileString)

let (repairedLines, issues) = await CSVErrorRepair.correctErrorsIn(
    lines,
    forUrl: fileURL,
    fieldTypes: fieldNameToTypes
)

if issues.issues.isEmpty {
    print("All errors repaired successfully")
} else {
    print("\(issues.issues.count) lines could not be fully repaired")
}

let output = CSVErrorRepair.convertToString(lines: repairedLines)
```

## Batch Processing

For processing multiple CSV files concurrently, the library provides two async methods that run each file's repair in parallel.

### From a Directory

```swift
// Filter to only process certain files
let fileFilter = { (file: URL) -> Bool in
    let suffix = String(file.deletingPathExtension().lastPathComponent.suffix(3))
    return Set(["evt", "rac", "res"]).contains(suffix)
}

// Map each file to its field type dictionary
let fileToFieldType = { (file: URL) -> [String: FieldType]? in
    let suffix = String(file.deletingPathExtension().lastPathComponent.suffix(3))
    let mappings: [String: [String: FieldType]] = [
        "evt": eventFieldTypes,
        "rac": raceFieldTypes,
        "res": resultFieldTypes,
    ]
    return mappings[suffix]
}

let allIssues = try await CSVErrorRepair.correctErrorsIn(
    directory: directoryURL,
    fileFilter: fileFilter,
    fileToFieldType: fileToFieldType
)

for fileIssue in allIssues where !fileIssue.issues.isEmpty {
    print("\(fileIssue.fileUrl.lastPathComponent): \(fileIssue.issues.count) unresolved issues")
}
```

### From Pre-loaded Data

If you already have file data in memory (e.g., downloaded from a server):

```swift
let files: [(URL, Data)] = [
    (url1, data1),
    (url2, data2),
]

let allIssues = try await CSVErrorRepair.correctErrorsIn(
    files: files,
    fileToFieldType: fileToFieldType
)
```

Both batch methods use `concurrentMap` to process files in parallel and return a `[FileIssues]` array summarizing any lines that could not be fully repaired.

## API Reference

### CSVErrorRepair

| Method | Description |
|---|---|
| `getLines(fromString:lineDelimeter:columnDelimeter:)` | Parse a CSV string into `[[String]]` |
| `getLines(fromData:lineDelimeter:columnDelimeter:encoding:)` | Parse `Data` into `[[String]]` |
| `convertToString(lines:columnDelimeter:lineDelimeter:checkForQuotes:)` | Convert line arrays back to a string |
| `convertToData(lines:columnDelimeter:lineDelimeter:encoding:)` | Convert line arrays back to `Data` |
| `findLinesWithErrors(fromString:)` | Find error lines from a raw CSV string |
| `findLinesWithIncorrectElementCount(fromLines:)` | Find lines with wrong column counts |
| `findAndRepairLinesWithTooFewElements(_:)` | Find and merge short lines in-place |
| `repairSequentialShortLines(lines:firstLineIndex:targetColumnCount:)` | Merge consecutive short lines starting at a given index |
| `repairLinesWithMoreColumnsBasedOnExpectedFields(forLine:expectedFieldTypes:fileName:lineNumber:)` | Repair a long line using field-type validation |
| `validate(separatedLine:againstExpectedFieldTypes:)` | Validate a line's fields against expected types, returning a `ValidationResultSet` |
| `correctErrorsIn(_:forUrl:fieldTypes:) async` | Apply both repairs to a single file's lines |
| `correctErrorsIn(directory:fileFilter:fileToFieldType:) async throws` | Batch-repair all CSV files in a directory |
| `correctErrorsIn(files:fileToFieldType:) async throws` | Batch-repair pre-loaded CSV file data |

### FieldType

Enum defining expected column data types. Used for long-line repair validation.

| Case | Parameters | Validates |
|---|---|---|
| `.integer` | `nullable`, `expectedValue`, `expectedLength` | Parses as `Int` with optional constraints |
| `.float` | `nullable` | Parses as `Float` |
| `.string` | `nullable`, `expectedLength`, `startsWith`, `contains` | Fixed-format string with optional constraints |
| `.unknownString` | `nullable` | Any non-empty string |
| `.date` | `nullable` | Format `yyyy-MM-dd` |
| `.dateTime` | *(none)* | Format `yyyy-MM-dd HH:mm:ss` |
| `.empty` | *(none)* | Empty string only |

### LineIssue

Describes a single line with an incorrect column count.

| Property | Type | Description |
|---|---|---|
| `lineIndex` | `Int` | Index of the problematic line |
| `columnCount` | `Int` | Actual number of columns |
| `expectedColumnCount` | `Int` | Expected number of columns (from header) |

### FileIssues

Groups unresolved issues for a single file after repair.

| Property | Type | Description |
|---|---|---|
| `fileUrl` | `URL` | The file that was processed |
| `issues` | `[LineIssue]` | Lines that still have incorrect column counts after repair |

### ValidationResultSet

Result of validating a line's fields from both directions. Used internally by the long-line repair algorithm.

| Property | Type | Description |
|---|---|---|
| `validatedIndicesForward` | `[Int]` | Indices validated scanning forward |
| `invalidIndiciesForward` | `[Int]` | First invalid index scanning forward |
| `lessValidatedIndicesForward` | `[Int]` | Indices with weaker validation (null/unknownString) forward |
| `validatedIndicesBackward` | `[Int]` | Indices validated scanning backward |
| `invalidIndicesBackward` | `[Int]` | First invalid index scanning backward |
| `lessValidatedIndicesBackward` | `[Int]` | Indices with weaker validation backward |

## License

MIT License. See [LICENSE](LICENSE) for details.
