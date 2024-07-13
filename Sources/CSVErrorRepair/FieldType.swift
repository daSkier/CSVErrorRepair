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

public enum FieldType: Sendable, Equatable, Hashable {
    case integer(nullable: Bool, expectedValue: Int?, expectedLength: Int?)
    case float(nullable: Bool)
    case string(nullable: Bool, expectedLength: Int?, startsWith: String?, contains: String?)
    case unknownString(nullable: Bool)
    case date(nullable: Bool)
    case dateTime
    case empty
}

extension FieldType {
    func validate(inputString input: String) -> ValidationResult {
        switch self {
        case .integer(let nullable, let expectedValue, let expectedLength):
            if input.isEmpty {
                return nullable ? .null : .invalid
            }else if let expectedValue {
                if let inputInt = Int(input) {
                    return inputInt == expectedValue ? .valid : .invalid
                }else{
                    return .invalid
                }
            }else if let expectedLength {
                if input.count == expectedLength {
                    return Int(input) != nil ? .valid : .invalid
                }else{
                    return .invalid
                }
            } else {
                return Int(input) != nil ? .valid : .invalid
            }
        case .float(let nullable):
            if input.isEmpty {
                return nullable ? .null : .invalid
            } else {
                return Float(input) != nil ? .valid : .invalid
            }
        case .string(let nullable, let expectedLength, let startsWith, let contains):
            if input.isEmpty {
                return nullable ? .null : .invalid
            }else if let expectedLength {
                if input.count == expectedLength {
                    if let startsWith {
                        return input.hasPrefix(startsWith) ? .valid : .invalid
                    } else {
                        return .valid
                    }
                } else {
                    return .invalid
                }
            }else if let startsWith {
                if let contains {
                    return input.hasPrefix(startsWith) && input.contains(contains) ? .valid : .invalid
                }else{
                    return input.hasPrefix(startsWith) ? .valid : .invalid
                }
            }else if let contains {
                if input.isEmpty {
                    return .null
                }else{
                    return input.contains(contains) ? .valid : .null
                }
            }else {
                print("failed to find expectedLength or startsWith")
                return .invalid
            }
        case .unknownString(let nullable):
            if input.isEmpty {
                return nullable ? .null : .invalid
            }else {
                return .unknownString
            }
        case .date:
            return dateWithDashesFormatter.date(from: input) != nil ? .valid : .invalid
        case .dateTime:
            return dateSpaceTimeFormatter.date(from: input) != nil ? .valid : .invalid
        case .empty:
            return input.isEmpty ? .valid : .invalid
        }
    }
}

enum ValidationResult {
    case valid
    case null
    case unknownString
    case invalid
}
