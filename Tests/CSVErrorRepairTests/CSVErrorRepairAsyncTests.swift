//
//  Test.swift
//  CSVErrorRepair
//
//  Created by Justin on 7/13/24.
//

import Testing
import CSVErrorRepair
import Foundation


struct AsyncSequenceLineSplittingTests {
    let AL1014racFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/PointsListArchives/ALFP1014F/AL1014rac.csv"
    let AL1919racFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/ALFP1919F/AL1919rac.csv"
    let AL1314racFilePath = "/Users/js/code/PointStalker/FISListArchivesUncrompressedCleaned/ALFP1314F/AL1314rac.csv"
    let AL919ptsShortFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/AL919pts-short.csv"
    let sampleDataDirPath = "/Users/js/code/PSVapor/PSSampleData/SampleData/"
    let AL1319EventWithLongLinePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/ALFP1319F/AL1319evt.csv"
    let fisArchives = "/Users/js/code/PointStalker/FISList Archives by Year"

    @Test(.disabled("URL line splitting is different without a way to override it")) func asyncLinesComparison() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.

        let asyncLines = try await withThrowingTaskGroup(of: [[String]].self) { group in
            var lines = [[String]]()
            for try await line in URL(fileURLWithPath: AL1014racFilePath).lines {
                lines.append(line.trimmingCharacters(in: .newlines).components(separatedBy: "\t"))
            }
            return lines
        }
        let fileString = try String(contentsOfFile: AL1014racFilePath, encoding: .isoLatin1)
        let syncLines = CSVErrorRepair.getLines(fromString: fileString)

        #expect(asyncLines == syncLines)
        try #require(asyncLines.count == syncLines.count)
        for i in 0..<asyncLines.count {
            #expect(asyncLines[i] == syncLines[i])
        }
    }

}
