# CSVErrorScanner
CSVs can be tough. In my history I've come across files that have errors due to user input such as lines getting split in two or having too many columns. This library has a few tools for finding and resolving those issues. 

The CSV issues this library seeks to resolve fall into two categories:
- **Lines that are too short** - This typically means the line has been split into separate lines and can be merged back together.
- **Lines that are too long** - This typically means the field/column was split due to the content including the separating character.

## Find Errors
Lines with errors are identified by compairing the column count of the first line against subsequent lines. If the subsequent lines have a different number of columns it is deemed as being an error. You can find these issues using `findLinesWithIncorrectElementCount`:
```Swift
static func findLinesWithIncorrectElementCount(fromLines separatedLines: [[String]]) -> [CSVLineIssue]
```
```Swift
struct CSVLineIssue {
    var lineIndex: Int
    var columnCount: Int
    var expectedColumnCount: Int
}
```

## Repair Split or Short Lines
To repair short lines that have been split into separate lines you can use `repairSequentialShortLines` that searches for sequential short lines that when added together are less than two lines in length. When found, it merges those lines together. 
```Swift
static func repairSequentialShortLines(lines: inout [[String]], firstLineIndex: Int, targetColumnCount: Int)
```

## Repair Long Lines
Merging together cells of a line together is more difficult because you have to identify which field are supposed to be merged together. This library approaches that problem by identfying the field type:
```Swift
enum FieldType: Equatable, Hashable {
    case integer(nullable: Bool, expectedValue: Int?, expectedLength: Int?)
    case float(nullable: Bool)
    case string(nullable: Bool, expectedLength: Int?, startsWith: String?, contains: String?)
    case unknownString(nullable: Bool)
    case date(nullable: Bool)
    case dateTime
    case empty
}
```
These are then used as part of a dictionary of column names: 
```Swift
let fieldNameToTypes: [String : FieldType] = [
        "id": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "code": .integer(nullable: false, expectedValue: nil, expectedLength: 4),
        "otherCode": .string(nullable: false, expectedLength: 2, startsWith: nil, contains: nil),
        "name": .unknownString(nullable: true), 
        "startDate": .date(nullable: false), 
        "endDate": .date(nullable: false),
        "location": .unknownString(nullable: true),
        "lastUpdate": .dateTime
    ]
```
The field type dictonary can then be used to validate each field from line start to line end and then separately in reverse. This helps create a heuristic for identifying which fields should be merged together as part of `repairLinesWithMoreColumnsBasedOnExpectedFields`:
```Swift
static func repairLinesWithMoreColumnsBasedOnExpectedFields(forLine separatedLine: inout [String], targetColumnCount: Int, expectedFieldTypes: [FieldType], fileName: String, lineNumber: Int) 
```
