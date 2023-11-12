//
//  LineScannerTests.swift
//  
//
//  Created by Justin on 9/2/23.
//

import XCTest
import CollectionConcurrencyKit
@testable import CSVErrorRepair

final class CSVErrorRepairTests: XCTestCase {

    let sampleRacErrorData = """
Raceid	Eventid	Seasoncode	Racecodex	Disciplineid	Disciplinecode	Catcode	Catcode2	Catcode3	Catcode4	Gender	Racedate	Starteventdate	Description	Place	Nationcode	Td1id	Td1name	Td1nation	Td1code	Td2id	Td2name	Td2nation	Td2code	Calstatuscode	Procstatuscode	Receiveddate	Pursuit	Masse	Relay	Distance	Hill	Style	Qualif	Finale	Homol	Webcomment	Displaystatus	Fisinterncomment	Published	Validforfispoints	Usedfislist	Tolist	Discforlistcode	Calculatedpenalty	Appliedpenalty	Appliedscala	Penscafixed	Version	Nationraceid	Provraceid	Msql7evid	Mssql7id	Results	Pdf	Topbanner	Bottombanner	Toplogo	Bottomlogo	Gallery	Indi	Team	Tabcount	Columncount	Level	Hloc1	Hloc2	Hloc3	Hcet1	Hcet2	Hcet3	Live	Livestatus1	Livestatus2	Livestatus3	Liveinfo1	Liveinfo2	Liveinfo3	Passwd	Timinglogo	validdate	TDdoc	Timingreport	Special_cup_points	Skip_wcsl	Lastupdate
95332	42845	2019	5159	0	GS	SAC				L	2018-09-01	2018-09-01	Giant Slalom	El Colorado	CHI	101144	Quiroga Eduardo (ARG)	ARG						N	V										10949/05/13				1	1	267	268		12.04	12.04		0	0	500000				1	0						0	0	0	0		10:15	12:15		15:15	17:15		1									2018-09-02	1	1	0	0	2018-09-06 08:28:03
95333	42845	2019	174	0	GS	SAC				M	2018-09-01	2018-09-01	Giant Slalom	El Colorado	CHI	101144	Quiroga Eduardo (ARG)	ARG	0					N	V									0	10949/05/13				1	1	267	268		4.96	6		0	0	500000				1	0						0	0	0	0		09:15	12:15		14:15	17:15		1									2018-09-02	1	1	0	0	2018-09-06 08:28:03
96226	43636	2019	249	0	GS	FIS				M	2019-03-14	2019-03-12	Giant Slalom	Squaw Valley	USA	101182	Perricone Roger (USA)	USA						R	V										11852/11/15.
	Replaces: Alyeska Resort			1	1	280	281		35.51	35.51		0	0	500000				1	0						0	0	0	0																	2019-03-14	1	1	0	0	2019-03-19 09:08:07
96227	43636	2019	5231	0	SL	FIS				L	2019-03-14	2019-03-12	Slalom	Alpine Meadows	USA	100656	Mahre Paul F. (USA)	USA						R	V									0	11852/11/15.
	Replaces: Alyeska Resort			1	1	280	281		57.98	57.98		0	0	500000				1	0						0	0	0	0																	2019-03-15	1	1	0	0	2019-03-19 09:08:07
96228	43636	2019	250	0	SL	FIS				M	2019-03-17	2019-03-12	Slalom	Alpine Meadows	USA	100656	Mahre Paul F. (USA)	USA						R	V									0		Replaces: Alyeska Resort			1	1	280	281		40	40		0	0	500000				1	0						0	0	0	0																	2019-03-17	1	1	0	0	2019-03-19 09:08:07
96229	43636	2019	5234	0	GS	FIS				L	2019-03-17	2019-03-12	Giant Slalom	Squaw Valley	USA	101182	Perricone Roger (USA)	USA						R	V									0		Replaces: Alyeska Resort			1	1	280	281		61.32	61.32		0	0	500000				1	0						0	0	0	0																	2019-03-17	1	1	0	0	2019-03-19 09:08:07
"""
    let AL1014racFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/PointsListArchives/ALFP1014F/AL1014rac.csv"
    let AL1919racFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/ALFP1919F/AL1919rac.csv"
    let AL919ptsShortFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/AL919pts-short.csv"
    let sampleDataDirPath = "/Users/js/code/PSVapor/PSSampleData/SampleData/"
    let AL1319EventWithLongLinePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/ALFP1319F/AL1319evt.csv"
    let fisArchives = "/Users/js/code/PointStalker/FISList Archives by Year"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindLinesWithErrors() throws {
        let errorLines = CSVErrorRepair.findLinesWithErrors(fromString: sampleRacErrorData)
        XCTAssertEqual(errorLines.count, 4)
        XCTAssertEqual(errorLines.map{ $0.lineIndex }, [3,4,5,6])
        print("error lines: \(errorLines)")
    }

    func testFindAndRepairLinesWithErrors() throws {
        var lines = CSVErrorRepair.getLines(fromString: sampleRacErrorData)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
        print("init lines element counts: \(lines.map{ $0.count })")
        CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
    }

    func testFindAndRepairLinesWithErrorsForFull1919raceFile() throws {
        let fileString = try String(contentsOfFile: AL1919racFilePath, encoding: .isoLatin1)
        var lines = CSVErrorRepair.getLines(fromString: fileString)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
        print("file:\n\(fileString)")
        print("initial line count: \(lines.count)")
        print("init lines element counts: \(lines.map{ $0.count })")
        CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
    }

    func testFindAndRepairLinesWithErrorsForFull1014raceFile() throws {
        let fileString = try String(contentsOfFile: AL1014racFilePath, encoding: .isoLatin1)
        var lines = CSVErrorRepair.getLines(fromString: fileString)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
        print("initial line count: \(lines.count)")
        print("init lines element counts: \(lines.map{ $0.count })")
        CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count < firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
    }

    func testFindAndRepairLinesWithErrorsForFull919ptsShortFile() throws {
        let fileString = try String(contentsOfFile: AL919ptsShortFilePath, encoding: .isoLatin1)
        var lines = CSVErrorRepair.getLines(fromString: fileString)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
        print("file:\n\(fileString)")
        print("initial line count: \(lines.count)")
        print("init lines element counts: \(lines.map{ $0.count })")
        CSVErrorRepair.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
    }

    func testCorrectErrorsInDirectory() async throws {
        let directoryUrl = URL(fileURLWithPath: fisArchives, isDirectory: true)
        let fileFilter = { (csvFile: URL) -> Bool in
            let expectedFisFileTypes = Set(["evt", "pts", "com", "rac", "res", "dis", "hdr", "cat"])
            let fileFisType = String(csvFile.deletingPathExtension().lastPathComponent.suffix(3))
            if !expectedFisFileTypes.contains(fileFisType) {
                if fileFisType != "eam" && fileFisType != "ted"{
                    print("found unexpected fis file type: \(fileFisType) for url: \(csvFile)")
                }
                return false
            }else{
                return true
            }
        }
        let fileToFildMapping = { (csvFile: URL) -> [String: FieldType]? in
            let fileFisType = String(csvFile.deletingPathExtension().lastPathComponent.suffix(3))
            let expectedFisFileHeaderDictionary = ["evt": SampleFieldMappings.eventFieldNameToTypes,
                                                   "pts": SampleFieldMappings.pointsFieldNameToTypes,
                                                   "com": SampleFieldMappings.athleteFieldNameToTypes,
                                                   "rac": SampleFieldMappings.raceFieldNameToTypes,
                                                   "res": SampleFieldMappings.raceResultFieldNameToTypes,
                                                   "dis": SampleFieldMappings.disFieldNameToTypes,
                                                   "hdr": SampleFieldMappings.hdrFieldNameToTypes,
                                                   "cat": SampleFieldMappings.catFieldNameToTypes]
            return expectedFisFileHeaderDictionary[fileFisType]
        }
        let fileErrors = try await CSVErrorRepair.correctErrorsIn(directory: directoryUrl,
                                                                   fileFilter: fileFilter,
                                                                   fileToFieldType: fileToFildMapping)
        let nonEmptyFileErrors = fileErrors.filter { $0.issues.count > 0 }
        let nonEmptyFileErrorDetails = nonEmptyFileErrors.reduce(into: []) { partialResult, fileIssues in
            return partialResult.append((fileUrl: fileIssues.fileUrl, issueCount: fileIssues.issues.count))
        }
        let totalLinesWithErrors = nonEmptyFileErrors.reduce(into: []) { partialResult, fileIssues in
            partialResult.append(contentsOf: fileIssues.issues)
        }
        let linesWithTooManyElements = totalLinesWithErrors.filter { $0.columnCount > $0.expectedColumnCount }
        print("files not solved with error correction:")
        print("found \(totalLinesWithErrors.count) lines with incorrect column counts")
        print("found \(linesWithTooManyElements.count) lines with too many columns")
        print("nonEmptyFileErrors.count: \(nonEmptyFileErrors.count)")
        nonEmptyFileErrors.forEach { print("\($0.fileUrl) -> \($0.issues)") }
        print("nonEmptyFileErrorDetails: \(nonEmptyFileErrorDetails)")
    }

    func testFindAndRepairLongLinesWithErrorsForFull1319EventFile() throws {
        let fileString = try String(contentsOfFile: AL1319EventWithLongLinePath, encoding: .isoLatin1)
        var lines = CSVErrorRepair.getLines(fromString: fileString)
        let fieldTypes = lines.first!.map { fieldName in
            guard let type = SampleFieldMappings.eventFieldNameToTypes[fieldName] else {
                fatalError("failed to get field type for \(fieldName)")
            }
            return type
        }
        let lineIssues = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)
        print("init lineIssues: \(lineIssues)")
        if lineIssues.count > 0 {
            for issueLine in lineIssues {
                CSVErrorRepair.repairSequentialShortLines(lines: &lines,
                                              firstLineIndex: issueLine.lineIndex,
                                              targetColumnCount: issueLine.expectedColumnCount)
            }
            lines.removeAll{ $0.count == 0 } // prevents issues with lines that end with /r
            lines.removeAll { $0.count == 1 && $0.first!.isEmpty } // prevents issues with lines that end with /r
            let linesWithIssuesAfterSequentialLineRepair = CSVErrorRepair.findLinesWithIncorrectElementCount(fromLines: lines)
            for issueLine in linesWithIssuesAfterSequentialLineRepair {
                CSVErrorRepair.repairLinesWithMoreColumnsBasedOnExpectedFields(forLine: &lines[issueLine.lineIndex],
                                                                        targetColumnCount: issueLine.expectedColumnCount,
                                                                        expectedFieldTypes: fieldTypes,
                                                                        fileName: "AL1319evt.csv",
                                                                        lineNumber: issueLine.lineIndex)
            }
        }
    }

    func testGetAllHeaders() async throws {
        let expectedTypes = Set(["evt", "pts", "com", "rac", "res", "dis", "hdr", "cat"])
        let directoryUrl = URL(fileURLWithPath: fisArchives, isDirectory: true)
        let enum1 = FileManager.default
            .enumerator(at: directoryUrl,
                        includingPropertiesForKeys: nil,
                        options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        let items = enum1?.allObjects as! [URL]
        let csvItems = items.filter { $0.lastPathComponent.hasSuffix("csv") }
            .filter { csvFile -> Bool in
                let expectedFisFileTypes = Set(["evt", "pts", "com", "rac", "res", "dis", "hdr", "cat"])
                let fileFisType = String(csvFile.deletingPathExtension().lastPathComponent.suffix(3))
                if !expectedFisFileTypes.contains(fileFisType) {
                    if fileFisType != "eam" && fileFisType != "ted"{
                        print("filtering out type: \(fileFisType) for url: \(csvFile)")
                    }
                    return false
                }else{
                    return true
                }
            }
        print("csvItems.count: \(csvItems.count)")
        let filesAndFirstLines = try await csvItems
            .concurrentMap { csvFile -> (lastPathComponent: String, fileType: String, firstLine: [String]) in
                return try autoreleasepool {
                    let fileString = try String(contentsOf: csvFile, encoding: .isoLatin1)
                    let lines = CSVErrorRepair.getLines(fromString: fileString)
                    let lastPathComponent = csvFile.deletingPathExtension().lastPathComponent
                    let fileFisType = String(csvFile.deletingPathExtension().lastPathComponent.suffix(3))
                    if !expectedTypes.contains(fileFisType) {
                        print("found unexpected fis file type: \(fileFisType) for url: \(csvFile)")
                    }
                    return (lastPathComponent: lastPathComponent, fileType: fileFisType, firstLine: lines.first!)
                }
            }
        let valuesByFileType = filesAndFirstLines.reduce(into: [String : Set<String>]()) { partialResult, fileInfo in
            if partialResult.keys.contains(fileInfo.fileType) {
                partialResult[fileInfo.fileType]?.formUnion(fileInfo.firstLine)
            }else{
                partialResult[fileInfo.fileType] = Set(fileInfo.firstLine)
            }
        }
        let valuesByFileTypeFiltered = valuesByFileType.filter { (key, value) -> Bool in
            return expectedTypes.contains(key)
        }
        for (key, value) in valuesByFileTypeFiltered {
            print("\(key): \(value)")
        }
    }
}

struct SampleFieldMappings {
    static let eventFieldNameToTypes: [String : FieldType] = [
        "Eventid": .integer(nullable: false, expectedValue: nil, expectedLength: nil), //Eventid
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: 4), //Seasoncode
        "Sectorcode": .string(nullable: false, expectedLength: 2, startsWith: nil, contains: nil), //Sectorcode
        "Eventname": .unknownString(nullable: true), //Eventname
        "Startdate": .date(nullable: false), //Startdate
        "Enddate": .date(nullable: false), //Enddate
        "Nationcodeplace": .string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil), //Nationcodeplace
        "Orgnationcode": .string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil), // Orgnationcode
        "Place": .unknownString(nullable: true), //Place
        "Published": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Published
        "OrgaddressL1": .unknownString(nullable: true), //OrgaddressL1
        "OrgaddressL2": .unknownString(nullable: true), //OrgaddressL2
        "OrgaddressL3": .unknownString(nullable: true), //OrgaddressL3
        "OrgaddressL4": .unknownString(nullable: true), //OrgaddressL4
        "Orgtel": .unknownString(nullable: true), //Orgtel
        "Orgmobile": .unknownString(nullable: true), //Orgmobile
        "Orgfax": .unknownString(nullable: true), //Orgfax
        "OrgEmail": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //OrgEmail
        "OrgEntryEmail": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"),
        "Orgemailentries": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailentries
        "Orgemailaccomodation": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailaccomodation
        "Orgemailtransportation": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailtransportation
        "OrgWebsite": .unknownString(nullable: true), //OrgWebsite
        "Socialmedia": .unknownString(nullable: true), //Socialmedia
        "Eventnotes": .unknownString(nullable: true), //Eventnotes
        "Languageused": .unknownString(nullable: true), //Languageused
        "Td1id": .unknownString(nullable: true), //Td1id
        "Td1name": .unknownString(nullable: true), //Td1name
        "Td1nation": .unknownString(nullable: true), //Td1nation
        "Td2id": .unknownString(nullable: true), //Td2id
        "Td2name": .unknownString(nullable: true), //Td2name
        "Td2nation": .unknownString(nullable: true), //Td2nation
        "Orgfee": .unknownString(nullable: true), //Orgfee
        "Bill": .unknownString(nullable: true), //Bill
        "Billdate": .unknownString(nullable: true), //Billdate
        "Selcat": .string(nullable: false, expectedLength: nil, startsWith: "-", contains: nil), //Selcat
        "Seldis": .string(nullable: false, expectedLength: nil, startsWith: "-", contains: nil), //Seldis
        "Seldisl": .unknownString(nullable: true), //Seldisl
        "Seldism": .unknownString(nullable: true), //Seldism
        "Dispdate": .unknownString(nullable: true), //Dispdate
        "Discomment": .unknownString(nullable: true), //Discomment
        "Version": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Version,
        "Nationeventid": .unknownString(nullable: true), //Nationeventid
        "Proveventid": .unknownString(nullable: true), //Proveventid
        "Mssql7id": .unknownString(nullable: true), //Mssql7id
        "Results": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Results
        "Pdf": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Pdf
        "Topbanner": .unknownString(nullable: true), //Topbanner
        "Bottombanner": .unknownString(nullable: true), //Bottombanner
        "Toplogo": .unknownString(nullable: true), //Toplogo
        "Bottomlogo": .unknownString(nullable: true), //Bottomlogo
        "Gallery": .unknownString(nullable: true), //Gallery
        "Nextracedate": .unknownString(nullable: true), //Nextracedate
        "Lastracedate": .unknownString(nullable: true), //Lastracedate
        "TDletter": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //TDletter
        "Orgaddressid": .unknownString(nullable: true), //Orgaddressid
        "Tournament": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Tournament
        "Parenteventid": .integer(nullable: true, expectedValue: nil, expectedLength: 1), //Parenteventid
        "Placeid": .integer(nullable: true, expectedValue: nil, expectedLength: nil), //Placeid
        "Lastupdate": .dateTime //Lastupdate
    ]

    static let raceFieldNameToTypes: [String : FieldType] = [
        "Raceid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Eventid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: 4),
        "Racecodex": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Disciplineid": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Disciplinecode": .unknownString(nullable: true),
        "Catcode": .unknownString(nullable: true),
        "Catcode2": .unknownString(nullable: true),
        "Catcode3": .unknownString(nullable: true),
        "Catcode4": .unknownString(nullable: true),
        "Gender": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Racedate": .date(nullable: false),
        "Starteventdate": .date(nullable: false),
        "Description": .unknownString(nullable: true),
        "Place": .unknownString(nullable: true),
        "Nationcode": .string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil),
        "Td1id": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Td1name": .unknownString(nullable: true),
        "Td1nation": .unknownString(nullable: true),
        "Td1code": .unknownString(nullable: true),
        "Td2id": .unknownString(nullable: true),
        "Td2name": .unknownString(nullable: true),
        "Td2nation": .unknownString(nullable: true),
        "Td2code": .unknownString(nullable: true),
        "Calstatuscode": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil), // could be an enum
        "Procstatuscode": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil), // could be an enum
        "Receiveddate": .empty,
        "Pursuit": .empty,
        "Masse": .empty,
        "Relay": .empty,
        "Distance": .empty,
        "Hill": .empty,
        "Style": .unknownString(nullable: true),
        "Qualif": .empty,
        "Finale": .unknownString(nullable: true),
        "Homol": .unknownString(nullable: true),
        "Webcomment": .unknownString(nullable: true),
        "Displaystatus": .unknownString(nullable: true),
        "Fisinterncomment": .unknownString(nullable: true),
        "Published": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Validforfispoints": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Usedfislist": .unknownString(nullable: true),
        "Tolist": .unknownString(nullable: true),
        "Discforlistcode": .empty,
        "Calculatedpenalty": .float(nullable: true),
        "Appliedpenalty": .float(nullable: true),
        "Appliedscala": .empty,
        "Penscafixed": .integer(nullable: true, expectedValue: 0, expectedLength: nil),
        "Version": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Nationraceid": .unknownString(nullable: true),
        "Provraceid": .empty,
        "Msql7evid": .empty,
        "Mssql7id": .empty,
        "Results": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Pdf": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Topbanner": .unknownString(nullable: true),
        "Bottombanner": .unknownString(nullable: true),
        "Toplogo": .unknownString(nullable: true),
        "Bottomlogo": .unknownString(nullable: true),
        "Gallery": .unknownString(nullable: true),
        "Indi": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Team": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Tabcount": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Columncount": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Level": .unknownString(nullable: true),
        "Hloc1": .unknownString(nullable: true),
        "Hloc2": .unknownString(nullable: true),
        "Hloc3": .unknownString(nullable: true),
        "Hcet1": .unknownString(nullable: true),
        "Hcet2": .unknownString(nullable: true),
        "Hcet3": .unknownString(nullable: true),
        "Live": .integer(nullable: true, expectedValue: nil, expectedLength: 1),
        "Livestatus": .unknownString(nullable: true),
        "Livestatus1": .unknownString(nullable: true),
        "Livestatus2": .unknownString(nullable: true),
        "Livestatus3": .unknownString(nullable: true),
        "Liveinfo": .unknownString(nullable: true),
        "Liveinfo1": .unknownString(nullable: true),
        "Liveinfo2": .unknownString(nullable: true),
        "Liveinfo3": .unknownString(nullable: true),
        "Passwd": .unknownString(nullable: true),
        "Timinglogo": .unknownString(nullable: true),
        "validdate": .date(nullable: true),
        "Validdate": .date(nullable: true),
        "Noepr": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "TDdoc": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Timingreport": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Special_cup_points": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Skip_wcsl": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Lastupdate": .dateTime,
        "Gender_2021": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
    ]
    static let raceResultFieldNameToTypes: [String : FieldType] = [
        "Recid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Raceid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Competitorid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Status": .unknownString(nullable: false),
        "Reason": .empty,
        "Status2": .empty,
        "Position": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Bib": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Fiscode": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Competitorname": .unknownString(nullable: false),
        "Nationcode": .unknownString(nullable: false),
        "Level": .integer(nullable: true, expectedValue: nil, expectedLength: 1),
        "Heat": .empty,
        "Timer1": .unknownString(nullable: true),
        "Timer2": .unknownString(nullable: true),
        "Timer3": .unknownString(nullable: true),
        "Timetot": .unknownString(nullable: true),
        "Valid": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Racepoints": .float(nullable: true),
        "Cuppoints": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Version": .empty,
        "Timer1int": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Timer2int": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Timer3int": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Timetotint": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Racepointsreceived": .float(nullable: true),
        "Listfispoints": .float(nullable: true),
        "Ptsmax": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Lastupdate": .dateTime
    ]
    static let athleteFieldNameToTypes: [String : FieldType] = [
        "Competitorid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Sectorcode": .string(nullable: false, expectedLength: nil, startsWith: "AL", contains: nil),
        "Fiscode": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Lastname": .unknownString(nullable: false),
        "Firstname": .unknownString(nullable: false),
        "Gender": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Birthdate": .date(nullable: true),
        "Nationcode": .unknownString(nullable: false),
        "Nationalcode": .unknownString(nullable: true),
        "Skiclub": .unknownString(nullable: true),
        "Association": .unknownString(nullable: true),
        "Status": .string(nullable: true, expectedLength: 1, startsWith: nil, contains: nil),
        "Status_old": .string(nullable: true, expectedLength: 1, startsWith: nil, contains: nil),
        "Statusnextlist": .unknownString(nullable: true),
        "Gender_2021": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
    ]
    static let pointsFieldNameToTypes: [String : FieldType] = [
        "Recid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Listid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Competitorid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Disciplinecode": .string(nullable: true, expectedLength: 2, startsWith: nil, contains: nil),
        "Basepoints": .float(nullable: true), // only in base lists?
        "Fispoints": .float(nullable: true),
        "Position": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Penalty": .string(nullable: true, expectedLength: 1, startsWith: "*", contains: nil),
        "Active": .empty,
        "Avenumresults": .empty,
        "Fixedbyfis": .string(nullable: true, expectedLength: 1, startsWith: "0", contains: nil),
        "Raceid1": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Raceid2": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Raceid3": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Version": .empty,
        "Pointspreviouslist": .empty,
        "pourcentpreviouslist": .string(nullable: false, expectedLength: 1, startsWith: "0", contains: nil),
        "Countlistsamestatus": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "pourcent": .integer(nullable: true, expectedValue: 0, expectedLength: nil),
        "Realpoints": .float(nullable: true),
        "blessevalide": .integer(nullable: false, expectedValue: 1, expectedLength: nil),
        "Youthpoints": .unknownString(nullable: true),
        "Lastupdate": .dateTime,
    ]
    static let catFieldNameToTypes: [String : FieldType] = [
        "Recid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Listid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Catcode": .unknownString(nullable: false),
        "Gender": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Minfispoints": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Maxfispoints": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Version": .integer(nullable: true, expectedValue: 0, expectedLength: nil),
        "Lastupdate": .dateTime,
    ]
    static let hdrFieldNameToTypes: [String : FieldType] = [
        "Recid": .integer(nullable: false, expectedValue: nil, expectedLength: nil), // only for base lists
        "Listalid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Listid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Listnumber": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Listname": .unknownString(nullable: false),
        "Speciallist": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Printdeadline": .unknownString(nullable: true),
        "Calculationdate": .date(nullable: false),
        "Startracedate": .date(nullable: false),
        "Endracedate": .date(nullable: false),
        "Validfrom": .date(nullable: false),
        "Validto": .date(nullable: false),
        "Published": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Version": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Lastupdate": .dateTime,
    ]
    static let disFieldNameToTypes: [String : FieldType] = [
        "Recid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Listid": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Disciplinecode": .unknownString(nullable: false),
        "Gender": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Xvalue": .empty,
        "Yvalue": .empty,
        "Zvalue": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Minpenalty": .unknownString(nullable: true),
        "Maxpenalty": .unknownString(nullable: true),
        "Fvalue": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Maxpoints": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Injuryminpen": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Injurymaxpen": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Injurypercentage": .float(nullable: true),
        "Version": .integer(nullable: true, expectedValue: nil, expectedLength: 1),
        "Adder0": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder1": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder2": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder3": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder4": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder5": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Adder6": .integer(nullable: false, expectedValue: nil, expectedLength: nil),
        "Lastupdate": .dateTime
    ]
}
