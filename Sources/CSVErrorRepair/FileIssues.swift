//
//  FileIssues.swift
//
//
//  Created by Justin on 11/12/23.
//

import Foundation

/// Groups all unresolved ``LineIssue`` values for a single CSV file after the repair process.
///
/// Returned by the batch processing methods
/// ``CSVErrorRepair/correctErrorsIn(directory:fileFilter:fileToFieldType:)`` and
/// ``CSVErrorRepair/correctErrorsIn(files:fileToFieldType:)``.
/// An empty ``issues`` array means all errors in the file were successfully repaired.
public struct FileIssues: Sendable {
    /// The URL of the CSV file that was processed.
    var fileUrl: URL
    /// Lines that still have an incorrect column count after all repairs were applied.
    var issues: [LineIssue]
}
