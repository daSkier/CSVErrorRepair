//
//  File.swift
//  
//
//  Created by Justin on 11/12/23.
//

struct ValidationResultSet {
    var validatedIndicesForward: [Int]
    var invalidIndiciesForward: [Int]
    var lessValidatedIndicesForward: [Int]
    var validatedIndicesBackward: [Int]
    var invalidIndicesBackward: [Int]
    var lessValidatedIndicesBackward: [Int]
    var lastValidForward: Int? { validatedIndicesForward.last }
    var lastLessValidForward: Int? { lessValidatedIndicesForward.last }
    var lastValidBackward: Int? { validatedIndicesBackward.last }
    var lastLessValidBackward: Int? { lessValidatedIndicesBackward.last }

    func validForwardBackDifferenceString() -> String {
        if let lastValidForward, let lastValidBackward {
            return "difference between forward/reverse valid indicies \(lastValidBackward-lastValidForward) (\(lastValidForward) vs. \(lastValidBackward)"
        }else{
            return "failed to get lastValidForward and/or lastValidBackward"
        }
    }

    func lessValidForwardBackDifferenceString() -> String {
        if let lastLessValidForward, let lastLessValidBackward {
            return "difference between forward/reverse lessValid indicies \(lastLessValidBackward-lastLessValidForward) (\(lastLessValidForward) vs. \(lastLessValidBackward)"
        }else{
            return "failed to get lastLessValidForward and/or lastLessValidBackward"
        }
    }

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

    func printResults() {
        print(validForwardBackDifferenceString())
        print(lessValidForwardBackDifferenceString())
        print("invalidIndicesForward: \(invalidIndiciesForward)")
        print("invalidIndicesBackward: \(invalidIndicesBackward)")
        print("valid indicies array: \(String(describing: try? mergedLastIndices()))")
    }
    enum ValidationResultSetError: Error {
        case oneLastIndicyNil
    }
}
