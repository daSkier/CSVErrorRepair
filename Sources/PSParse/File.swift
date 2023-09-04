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

enum FieldTypes {
    case integer(expectedValue: Int?, expectedLength: Int?)
    case float
    case string(expectedLength: Int?)
    case date
    case dateTime
}

extension FieldTypes {
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
                    if let inputInt = Int(input) {
                        return true
                    }else{
                        return false
                    }
                }else{
                    return false
                }
            } else {
                if let inputInt = Int(input) {
                    return true
                } else {
                    return false
                }
            }
        case .float:
            if let inputFloat = Float(input) {
                return true
            }else{
                return false
            }
        case .string(let expectedLength):
            return input.count == expectedLength
        case .date:
            if let date = dateWithDashesFormatter.date(from: input) {
                return true
            }else{
                return false
            }
        case .dateTime:
            if let date = dateSpaceTimeFormatter.date(from: input) {
                return true
            }else{
                return false
            }
        }
    }
}
