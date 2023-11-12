# CSVErrorScanner
CSVs can be tough. In my history I've come across files that have errors due to user input such as lines getting split in two or having too many columns. This library has a few tools for finding and resolving those issues. 

The CSV issues this library seeks to resolve fall into two categories:
- **Lines that are too short** - This typically means the line has been split into separate lines and can be merged back together.
- **Lines that are too long** - This typically means the field/column was split due to the content including the separating character.

## Operate On Lines
This package attempts to minimize copies by operating on arrays of `SubString`. As a result, many functions take a parameter of `[[String]]` and repair functions will use `inout` to apply fixes in place. `CSVErrorScanner` has a utility function `getLines(fromString inputString: String)` to produce this array. 
```Swift
struct CSVErrorScanner {
    static func getLines(fromString inputString: String) -> [[String]] { ... }
    ...
}
```
**Example:**
```Swift
let fileString = try String(contentsOfFile: "/SampleData/test.csv", encoding: .isoLatin1)
var lines = CSVErrorScanner.getLines(fromString: fileString)
```

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

## Applying Both Repairs
To apply both sets of repairs at once you can use, both functions run each file's error correction in parrallel: 
```Swift
static func correctErrorsIn(_ lines: inout [[String]], forUrl url: URL, fieldTypes: [String : FieldType]) throws -> CSVFileIssues
```

## Tools For Collections
There are two methods for running repairs on many files at once: 
```Swift
struct CSVErrorScanner {
    ...
    static func correctErrorsIn(files: [(URL, Data)], fileToFieldType: @escaping (URL) -> [String : FieldType]?) async throws -> [CSVFileIssues] { ... }
    static func correctErrorsIn(directory: URL, fileFilter: (URL) -> Bool, fileToFieldType: @escaping (URL) -> [String : FieldType]?) async throws -> [CSVFileIssues] { ... }
    ...
```
Both functions take a closure for determining the field mapping to use in the case that you have a heterogeneous mix of file structures.
```Swift
let fileToFildMapping = { (csvFile: URL) -> [String: FieldType]? in
    let fileFisType = String(csvFile.deletingPathExtension().lastPathComponent.suffix(3))
    let expectedFisFileHeaderDictionary = ["abc": SampleFieldMappings.abcFieldNameToTypes,
                                           "def": SampleFieldMappings.defFieldNameToTypes]
    return expectedFisFileHeaderDictionary[fileFisType]
}
```
Similarly, the directory version has a colsure to allow for applying a file filter.
```Swift
let fileFilter = { (csvFile: URL) -> Bool in
    let expectedFisFileTypes = Set(["abc", "def"])
    let fileFisType = String(csvFile.deletingPathExtension().lastPathComponent.suffix(3))
    if !expectedFisFileTypes.contains(fileFisType) {
        return false
    }else{
        return true
    }
}
```
