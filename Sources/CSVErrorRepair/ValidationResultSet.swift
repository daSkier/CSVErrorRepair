//
//  ValidationResultSet.swift
//
//
//  Created by Justin on 11/12/23.
//

/// The result of validating a CSV line's fields from both directions against expected ``FieldType`` values.
///
/// ``CSVErrorRepair/validate(separatedLine:againstExpectedFieldTypes:targetColumnCount:)`` scans
/// a line forward (from index 0) and backward (from the last index) until it encounters an invalid
/// field in each direction. The gap between the forward and backward validated ranges identifies
/// the region where the extra delimiter likely caused fields to shift.
///
/// This struct groups the validated, less-validated (null/unknownString matches), and invalid
/// indices from each scan direction. The ``mergedLastIndices()`` method combines these boundary
/// indices into a sorted list of candidate merge points for the repair algorithm.
public struct ValidationResultSet {
    /// Column indices that fully validated when scanning forward from the start.
    var validatedIndicesForward: [Int]
    /// Column indices that failed validation when scanning forward.
    var invalidIndiciesForward: [Int]
    /// Column indices with weaker validation (null or unknownString) when scanning forward.
    var lessValidatedIndicesForward: [Int]
    /// Column indices that fully validated when scanning backward from the end.
    var validatedIndicesBackward: [Int]
    /// Column indices that failed validation when scanning backward.
    var invalidIndicesBackward: [Int]
    /// Column indices with weaker validation (null or unknownString) when scanning backward.
    var lessValidatedIndicesBackward: [Int]

    /// The last fully validated index from the forward scan, or `nil` if none validated.
    var lastValidForward: Int? { validatedIndicesForward.last }
    /// The last weakly validated index from the forward scan, or `nil` if none matched.
    var lastLessValidForward: Int? { lessValidatedIndicesForward.last }
    /// The last fully validated index from the backward scan, or `nil` if none validated.
    var lastValidBackward: Int? { validatedIndicesBackward.last }
    /// The last weakly validated index from the backward scan, or `nil` if none matched.
    var lastLessValidBackward: Int? { lessValidatedIndicesBackward.last }

    /// Returns a human-readable string describing the gap between the forward and backward fully-validated boundaries.
    func validForwardBackDifferenceString() -> String {
        if let lastValidForward, let lastValidBackward {
            return "difference between forward/reverse valid indicies \(lastValidBackward-lastValidForward) (\(lastValidForward) vs. \(lastValidBackward)"
        }else{
            return "failed to get lastValidForward and/or lastValidBackward"
        }
    }

    /// Returns a human-readable string describing the gap between the forward and backward weakly-validated boundaries.
    func lessValidForwardBackDifferenceString() -> String {
        if let lastLessValidForward, let lastLessValidBackward {
            return "difference between forward/reverse lessValid indicies \(lastLessValidBackward-lastLessValidForward) (\(lastLessValidForward) vs. \(lastLessValidBackward)"
        }else{
            return "failed to get lastLessValidForward and/or lastLessValidBackward"
        }
    }

    /// Combines the last validated index from each scan direction and validation level into a sorted array.
    ///
    /// The resulting indices represent candidate merge points for the long-line repair algorithm.
    /// Requires all four boundary indices to be non-nil.
    ///
    /// - Throws: ``ValidationResultSetError/oneLastIndicyNil`` if any boundary index is `nil`.
    /// - Returns: A sorted array of four indices: the last valid/lessValid forward and backward boundaries.
    func mergedLastIndices() throws -> [Int] {
        if let lastValidForward, let lastValidBackward, let lastLessValidForward, let lastLessValidBackward {
            return [
                lastValidForward,
                lastLessValidForward,
                lastValidBackward,
                lastLessValidBackward
            ].sorted()
        }else {
            print("failed to get mergedLastIndicies - lastValidForward: \(String(describing: lastValidForward)) / lastValidBackward: \(String(describing: lastValidBackward)) / lastLessValidForward: \(String(describing: lastLessValidForward)) / lastLessValidBackward: \(String(describing: lastLessValidBackward))")
            throw ValidationResultSetError.oneLastIndicyNil
        }
    }

    /// Prints a diagnostic summary of the validation results to standard output.
    func printResults() {
        print(validForwardBackDifferenceString())
        print(lessValidForwardBackDifferenceString())
        print("invalidIndicesForward: \(invalidIndiciesForward)")
        print("invalidIndicesBackward: \(invalidIndicesBackward)")
        print("valid indicies array: \(String(describing: try? mergedLastIndices()))")
    }
    /// Errors that can occur when computing merged indices from a ``ValidationResultSet``.
    public enum ValidationResultSetError: Error {
        /// One or more of the four boundary indices (lastValidForward, lastLessValidForward, lastValidBackward, lastLessValidBackward) was `nil`.
        case oneLastIndicyNil
    }
}
