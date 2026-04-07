//
//  FieldType.swift
//
//
//  Created by Justin on 9/4/23.
//

import Foundation

/// Date formatter for `yyyy-MM-dd HH:mm:ss` used by ``FieldType/dateTime``.
let dateSpaceTimeFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
    return formatter
}()

/// Date formatter for `yyyy-MM-dd` used by ``FieldType/date(nullable:)``.
let dateWithDashesFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

/// Describes the expected data type of a CSV column, used by the long-line repair algorithm
/// to determine where a delimiter was erroneously introduced inside a field value.
///
/// Each case carries parameters that refine the validation check. The ``nullable`` parameter
/// (where available) controls whether an empty string is treated as a valid null value or an error.
///
/// ## Topics
///
/// ### Numeric Types
/// - ``integer(nullable:expectedValue:expectedLength:)``
/// - ``float(nullable:)``
///
/// ### String Types
/// - ``string(nullable:expectedLength:startsWith:contains:)``
/// - ``unknownString(nullable:)``
///
/// ### Date Types
/// - ``date(nullable:)``
/// - ``dateTime``
///
/// ### Special
/// - ``empty``
public enum FieldType: Sendable, Equatable, Hashable {
    /// An integer field. Optionally validates an exact expected value or a specific digit count.
    ///
    /// - Parameters:
    ///   - nullable: Whether an empty string is accepted as a null value.
    ///   - expectedValue: If non-nil, the parsed integer must equal this value exactly.
    ///   - expectedLength: If non-nil, the string representation must have exactly this many characters.
    case integer(nullable: Bool, expectedValue: Int?, expectedLength: Int?)

    /// A floating-point number field.
    ///
    /// - Parameter nullable: Whether an empty string is accepted as a null value.
    case float(nullable: Bool)

    /// A constrained string field with optional length, prefix, and substring checks.
    ///
    /// - Parameters:
    ///   - nullable: Whether an empty string is accepted as a null value.
    ///   - expectedLength: If non-nil, the string must have exactly this many characters.
    ///   - startsWith: If non-nil, the string must begin with this prefix.
    ///   - contains: If non-nil, the string must contain this substring.
    case string(nullable: Bool, expectedLength: Int?, startsWith: String?, contains: String?)

    /// A flexible string field that accepts any non-empty value.
    ///
    /// Use this for columns whose content is unpredictable (e.g., names, free-text).
    /// Returns ``ValidationResult/unknownString`` on validation rather than ``ValidationResult/valid``,
    /// giving it lower priority when the repair algorithm compares merge candidates.
    ///
    /// - Parameter nullable: Whether an empty string is accepted as a null value.
    case unknownString(nullable: Bool)

    /// A date field matching the format `yyyy-MM-dd`.
    ///
    /// - Parameter nullable: Whether an empty string is accepted as a null value.
    case date(nullable: Bool)

    /// A date-time field matching the format `yyyy-MM-dd HH:mm:ss`.
    case dateTime

    /// A field that must be an empty string.
    case empty
}

extension FieldType {
    /// Validates a string value against this field type's constraints.
    ///
    /// - Parameter input: The field value to validate.
    /// - Returns: A ``ValidationResult`` indicating whether the value is valid, null, an unknown string, or invalid.
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

/// The result of validating a single field value against a ``FieldType``.
enum ValidationResult {
    /// The value fully satisfies the field type's constraints.
    case valid
    /// The value is empty and the field type allows nulls.
    case null
    /// The value is a non-empty string matched by ``FieldType/unknownString(nullable:)``.
    case unknownString
    /// The value does not satisfy the field type's constraints.
    case invalid
}
