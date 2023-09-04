//
//  File.swift
//  
//
//  Created by Justin on 9/4/23.
//

import Foundation

let dateSpaceTimeFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
    return formatter
}()

let dateWithDashesFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

enum FieldType: Equatable, Hashable {
    case integer(expectedValue: Int?, expectedLength: Int?)
    case float
    case string(expectedLength: Int)
    case unknownString
    case date
    case dateTime
}

extension FieldType {
    func validate(inputString input: String) -> Bool {
        switch self {
        case .integer(let expectedValue, let expectedLength):
            if let expectedValue {
                if let inputInt = Int(input) {
                    return inputInt == expectedValue
                }else{
                    return false
                }
            }else if let expectedLength {
                if input.count == expectedLength {
                    return Int(input) != nil
                }else{
                    return false
                }
            } else {
                return Int(input) != nil
            }
        case .float:
            return Float(input) != nil
        case .string(let expectedLength):
            return input.count == expectedLength
        case .unknownString:
            return true
        case .date:
            return dateWithDashesFormatter.date(from: input) != nil
        case .dateTime:
            return dateSpaceTimeFormatter.date(from: input) != nil
        }
    }
}
