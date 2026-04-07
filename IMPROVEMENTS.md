# CSVErrorRepair — Planned Improvements

This document catalogs known logic bugs, crash risks, thread-safety issues, performance opportunities, and maintainability improvements identified in the library. Items are grouped by category and ordered by impact within each group.

---

## Logic Bugs

### ~~1. `date(nullable:)` ignores the `nullable` parameter~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/FieldType.swift`, `validate(inputString:)` — `.date` case

**Problem:** The `.date` case passes the input directly to `DateFormatter` without first checking for an empty string. When a field is configured as `.date(nullable: true)` and receives an empty value, the formatter returns `nil` and the method returns `.invalid` instead of `.null`.

**Fix:** Add the same empty-string guard used by every other nullable case:

```swift
// Before:
case .date:
    return dateWithDashesFormatter.date(from: input) != nil ? .valid : .invalid

// After:
case .date(let nullable):
    if input.isEmpty { return nullable ? .null : .invalid }
    return dateWithDashesFormatter.date(from: input) != nil ? .valid : .invalid
```

---

### ~~2. `string` validation ignores `contains` when `expectedLength` is set~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/FieldType.swift`, `validate(inputString:)` — `.string` case

**Problem:** When `expectedLength` is non-nil, the code checks length and optionally `startsWith`, but never checks `contains`. A field configured as `.string(nullable: false, expectedLength: 5, startsWith: nil, contains: "abc")` accepts any 5-character string regardless of whether it contains `"abc"`.

**Fix:** After the length check passes, also check `startsWith` and `contains` if they are set:

```swift
case .string(let nullable, let expectedLength, let startsWith, let contains):
    if input.isEmpty { return nullable ? .null : .invalid }
    if let expectedLength, input.count != expectedLength { return .invalid }
    if let startsWith, !input.hasPrefix(startsWith) { return .invalid }
    if let contains, !input.contains(contains) { return .invalid }
    // If we reach here, all present constraints passed
    return .valid
```

This flattened structure also resolves issues 3 and eliminates the nested `if let` chain.

---

### ~~3. `string` with no constraints returns `.invalid`~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/FieldType.swift`, `validate(inputString:)` — `.string` case, bottom of the chain

**Problem:** `.string(nullable: false, expectedLength: nil, startsWith: nil, contains: nil)` falls through all the `if let` branches and hits:

```swift
print("failed to find expectedLength or startsWith")
return .invalid
```

This is a valid configuration (a non-empty string with no further constraints) and should succeed.

**Fix:** Addressed by the flattened validation structure in issue 2 above. When no constraints are set, all `if let` checks are skipped and the method returns `.valid`.

---

### ~~4. `findLinesWithErrors` does not skip trailing empty lines~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `findLinesWithErrors(fromString:)`

**Problem:** `findLinesWithIncorrectElementCount(fromLines:)` skips a trailing empty line (common in files ending with `\r` or `\n`), but `findLinesWithErrors(fromString:)` did not. The two functions returned different results for the same input.

**Fix:** `findLinesWithErrors` now delegates to `findLinesWithIncorrectElementCount`, ensuring consistent behavior:

```swift
public static func findLinesWithErrors(fromString inputString: String) -> [LineIssue] {
    let separatedLines = Self.getLines(fromString: inputString)
    return Self.findLinesWithIncorrectElementCount(fromLines: separatedLines)
}
```

---

### ~~5. Misleading guard-failure message~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `repairLinesWithMoreColumnsBasedOnExpectedFields`

**Problem:** The guard printed `"expectedFieldTypes.count == targetColumnCount"` when the guard *failed*, implying they were equal when they were not.

**Fix:** Changed the message to describe the actual failure with the concrete values:

```swift
print("expectedFieldTypes.count (\(expectedFieldTypes.count)) != targetColumnCount (\(targetColumnCount)) in \(#function)")
```

---

## Crash Risks

### ~~6. `repairSequentialShortLines` can index out of bounds~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `repairSequentialShortLines`

**Problem:** `linesAhead` is incremented at the top of a `repeat` loop before checking array bounds. If the short line is near the end of the file, `lines[firstLineIndex + linesAhead]` will crash with an index-out-of-range error.

**Fix:** Added a bounds check at the top of the loop:

```swift
repeat {
    linesAhead += 1
    guard firstLineIndex + linesAhead < lines.count else { return }
    // ... rest of loop
```

---

### ~~7. Force casts and `fatalError` in batch methods~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `correctErrorsIn(directory:...)`, `correctErrorsIn(files:...)`, and `correctErrorsIn(_:forUrl:fieldTypes:)`

**Problem:** Several lines would crash the entire process on bad input instead of throwing:

- `enum1?.allObjects as! [URL]` — force cast; crashes if the enumerator is nil (invalid directory).
- `fatalError("failed to get file mapping dict")` — crashes instead of throwing. Both batch methods already declare `throws`, so this could be an error.
- `lines.first!` — force unwrap after `removeAll`; crashes if lines become empty (degenerate input).

**Fix:** Replaced each crash point with a thrown error. Added new cases to `ParseError`:

```swift
case directoryEnumerationFailed(URL)
case missingFieldTypeMapping(URL)
case emptyFileAfterCleanup(URL)
case unknownFieldName(String, URL)
```

All `fatalError` calls replaced with `throw`, `as!` replaced with `guard let ... as?`, and `lines.first!` replaced with `guard let header = lines.first`.

**Note:** `correctErrorsIn(_:forUrl:fieldTypes:)` signature changed from `async ->` to `async throws ->` — this is a breaking API change for callers.

---

## Thread Safety

### ~~8. `DateFormatter` is not thread-safe under concurrent access~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/FieldType.swift`, top-level `let dateSpaceTimeFormatter` and `let dateWithDashesFormatter`

**Problem:** `DateFormatter` is not thread-safe. The two global instances were shared across all concurrent tasks. When the batch methods use `concurrentMap`, multiple threads call `date(from:)` on the same formatter simultaneously, which is a data race that can cause intermittent crashes or incorrect results.

**Fix:** Option A — Regex validation. Replaced both `DateFormatter` instances with inline regex patterns in the `validate` method:

```swift
case .date(let nullable):
    if input.isEmpty { return nullable ? .null : .invalid }
    return input.wholeMatch(of: /^\d{4}-\d{2}-\d{2}$/) != nil ? .valid : .invalid

case .dateTime:
    if input.isEmpty { return .invalid }
    return input.wholeMatch(of: /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/) != nil ? .valid : .invalid
```

This is inherently thread-safe, faster, eliminates the global mutable state, and is compatible with Swift 6 strict concurrency. The global `DateFormatter` instances have been removed entirely.

**Note:** The regex validates structural format only (four-digit year, two-digit month/day/hour/minute/second), not calendar validity (e.g. `2023-02-30` would pass). This matches the library's existing behavior — it only checks whether a field *looks like* a date, not whether it represents a real calendar date. The regex is also stricter than `DateFormatter` in some cases (e.g. slash-separated dates that `DateFormatter` would leniently accept are now correctly rejected).

---

## Performance

### 9. `repairLinesWithMoreColumnsBasedOnExpectedFields` stores unused array copies

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `repairLinesWithMoreColumnsBasedOnExpectedFields`

**Problem:** Each entry in the `mergeResults` array stores `resultLine: [String]` (a full copy of the line) and `invalidIndicesForward: [Int]`, but only `invalidIndicesCount` is ever read afterward. For wide CSV files (80+ columns), this allocates and copies 4+ arrays per repair call for no reason.

**Fix:** Only store what's needed:

```swift
var mergeResults: [(mergeIndex: Int, invalidIndicesCount: Int)] = []

for mergeIndex in lastIndicies {
    var mergedLine = separatedLine
    mergedLine[mergeIndex] = mergedLine[mergeIndex] + mergedLine[mergeIndex + 1]
    mergedLine.remove(at: mergeIndex + 1)

    let postMergeValidation = Self.validate(...)
    mergeResults.append((mergeIndex: mergeIndex,
                         invalidIndicesCount: postMergeValidation.invalidIndiciesForward.count))
}
```

---

### 10. Redundant sort before min

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `repairLinesWithMoreColumnsBasedOnExpectedFields`

**Problem:** `finalMergeResults` is sorted by `invalidIndicesCount` (O(n log n)), then `.min` is called (O(n)). Since only the minimum is needed, the sort is wasted work.

**Fix:** Remove the sort. Use `.min` on the unsorted array, then `.filter` for ties:

```swift
let minErrors = mergeResults.min { $0.invalidIndicesCount < $1.invalidIndicesCount }?.invalidIndicesCount
if let minErrors {
    let minErrorResults = mergeResults.filter { $0.invalidIndicesCount == minErrors }
    // ... pick from minErrorResults
}
```

---

### 11. `mergedLastIndices()` returns duplicate indices

**File:** `Sources/CSVErrorRepair/ValidationResultSet.swift`, `mergedLastIndices()`

**Problem:** `validatedIndicesForward` is always a subset of `lessValidatedIndicesForward`, so `lastValidForward` and `lastLessValidForward` are often the same value (same for the backward pair). The returned array can contain duplicates, causing the repair algorithm to try the same merge point multiple times.

**Fix:** Deduplicate before returning:

```swift
func mergedLastIndices() throws -> [Int] {
    guard let a = lastValidForward, let b = lastValidBackward,
          let c = lastLessValidForward, let d = lastLessValidBackward else {
        throw ValidationResultSetError.oneLastIndicyNil
    }
    return Array(Set([a, b, c, d])).sorted()
}
```

---

### 12. Two `removeAll` passes where one would suffice

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift` — appears in `findAndRepairLinesWithTooFewElements`, `correctErrorsIn(directory:...)`, `correctErrorsIn(files:...)`, and `correctErrorsIn(_:forUrl:fieldTypes:)`

**Problem:** Two sequential `removeAll` calls each scan the entire array:

```swift
lines.removeAll { $0.count == 0 }
lines.removeAll { $0.count == 1 && $0.first!.isEmpty }
```

**Fix:** Combine into a single pass:

```swift
lines.removeAll { $0.isEmpty || ($0.count == 1 && $0.first!.isEmpty) }
```

---

### 13. `getLines` uses two `.map` passes creating an intermediate array

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `getLines(fromString:...)`

**Problem:** Two chained `.map` calls create an intermediate `[String]` array between them.

**Fix:** Combine into a single `.map`:

```swift
inputString.components(separatedBy: lineDelimeter).map {
    $0.trimmingCharacters(in: .newlines).components(separatedBy: columnDelimeter)
}
```

---

### 14. `convertToString` inner map runs even when `checkForQuotes` is `false`

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`, `convertToString`

**Problem:** When `checkForQuotes` is `false`, the inner `.map` iterates every cell but always returns the cell unchanged, allocating a new array identical to the input.

**Fix:** Short-circuit when quotes don't need checking:

```swift
lines.map { cells -> String in
    if checkForQuotes {
        return cells.map { $0.replacingOccurrences(of: "\"", with: "") }.joined(separator: columnDelimeter)
    } else {
        return cells.joined(separator: columnDelimeter)
    }
}.joined(separator: lineDelimeter)
```

---

## Maintainability

### ~~15. Repair pipeline is duplicated three times~~ (RESOLVED)

**File:** `Sources/CSVErrorRepair/CSVErrorRepair.swift`

**Problem:** The full repair sequence (find issues → merge short lines → remove empties → find remaining → build field type array → repair long lines → find remaining) was copy-pasted across three methods:

- `correctErrorsIn(directory:fileFilter:fileToFieldType:)`
- `correctErrorsIn(files:fileToFieldType:)`
- `correctErrorsIn(_:forUrl:fieldTypes:)`

Any bug fix had to be applied in all three places, and they could easily drift out of sync.

**Fix:** Extracted the shared pipeline into `private static func repairLines(_:fieldTypeMapping:fileName:fileUrl:) throws -> [LineIssue]`. All three public methods now delegate to this helper, reducing each to a few lines. Future pipeline changes only need to be made in one place.

---

### 16. Adopt typed throws — DEFERRED

**Files:** `Sources/CSVErrorRepair/CSVErrorRepair.swift` — `getLines(fromData:...)`, `correctErrorsIn(directory:...)`, `correctErrorsIn(files:...)`

**Problem:** These methods declare `throws` but only ever throw `ParseError` cases. Callers must catch a generic `Error` and downcast, losing type safety.

**Status:** Investigated and deferred. While issue 7 has been resolved (all `fatalError` paths are now proper throws), adopting typed throws is blocked by ecosystem limitations:

1. **CollectionConcurrencyKit blocker.** The batch methods use `concurrentMap` from CollectionConcurrencyKit, which declares untyped `async throws`. Even if the public methods were changed to `throws(ParseError)`, the compiler would reject it because `concurrentMap` erases the error type to `any Error`.

2. **`Task` does not support typed throws.** `Task` constructors require `Failure == any Error` — there is no way to create `Task<T, ParseError>`. This is an [open Swift issue](https://github.com/swiftlang/swift/issues/74556) requiring a separate Swift Evolution proposal.

3. **SE-0413 guidance discourages broad adoption.** The proposal states: *"the existing (untyped) `throws` remains the better default error-handling mechanism for most Swift code."* Typed throws is recommended primarily for Embedded Swift, generic error propagation, and sealed internal APIs.

**Revisit when:** Either CollectionConcurrencyKit is replaced with `withThrowingTaskGroup` (which does support typed throws), or `Task` gains typed throws support in a future Swift release.

---

### 17. Derive `targetColumnCount` from `expectedFieldTypes.count`

**Files:** `Sources/CSVErrorRepair/CSVErrorRepair.swift` — `repairLinesWithMoreColumnsBasedOnExpectedFields` and `validate(separatedLine:againstExpectedFieldTypes:targetColumnCount:)`

**Problem:** Both methods take a `targetColumnCount` parameter that must always equal `expectedFieldTypes.count` (enforced by a guard in the repair method). This is redundant — the count is already implicit in the array length — and creates a source of caller error if the two values ever diverge.

**Fix:** Remove the `targetColumnCount` parameter and derive it internally:

```swift
public static func repairLinesWithMoreColumnsBasedOnExpectedFields(
    forLine separatedLine: inout [String],
    expectedFieldTypes: [FieldType],
    fileName: String,
    lineNumber: Int
) {
    let targetColumnCount = expectedFieldTypes.count
    // ... rest of method unchanged
}

public static func validate(
    separatedLine: [String],
    againstExpectedFieldTypes: [FieldType]
) -> ValidationResultSet {
    let targetColumnCount = againstExpectedFieldTypes.count
    // ... rest of method unchanged
}
```

**Note:** This is a breaking API change. If you need to preserve backwards compatibility, mark the old signatures `@available(*, deprecated)` and have them forward to the new versions.

---

## Suggested implementation order

The items above are independent and can be tackled in any order. However, the following sequence minimizes risk and maximizes value:

1. ~~**Issues 1–3** (FieldType validation bugs) — RESOLVED~~
2. ~~**Issue 8** (DateFormatter thread safety) — RESOLVED via regex replacement~~
3. ~~**Issue 6** (bounds check) — RESOLVED~~
4. ~~**Issue 7** (fatalError → throw) — RESOLVED with new ParseError cases~~
5. ~~**Issue 15** (extract repair helper) — RESOLVED~~
6. ~~**Issues 4–5** (consistency / messaging) — RESOLVED~~
7. **Issue 16** (typed throws) — DEFERRED due to CollectionConcurrencyKit and Task limitations.
8. **Issue 17** (derive targetColumnCount) — remove redundant parameter after API is stabilized.
9. **Issues 9–14** (performance) — optimizations, impact scales with file size and column count.
