//
//  File.swift
//  
//
//  Created by Justin on 11/12/23.
//

import Foundation

public struct FileIssues: Sendable {
    var fileUrl: URL
    var issues: [LineIssue]
}
