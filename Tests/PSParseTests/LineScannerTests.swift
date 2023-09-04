//
//  LineScannerTests.swift
//  
//
//  Created by Justin on 9/2/23.
//

import XCTest
@testable import PSParse

final class LineScannerTests: XCTestCase {

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
    let AL1919racFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/ALFP1919F/AL1919rac.csv"
    let AL919ptsShortFilePath = "/Users/js/code/PSVapor/PSSampleData/SampleData/AL919pts-short.csv"
    let sampleDataDirPath = "/Users/js/code/PSVapor/PSSampleData/SampleData/"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindLinesWithErrors() throws {
        let scanner = LineScanner()
        let errorLines = scanner.findLinesWithErrors(fromString: sampleRacErrorData)
        XCTAssertEqual(errorLines.count, 4)
        XCTAssertEqual(errorLines.map{ $0.lineIndex }, [3,4,5,6])
        print("error lines: \(errorLines)")
    }

    func testFindAndRepairLinesWithErrors() throws {
        let scanner = LineScanner()
        var lines = scanner.getLines(fromString: sampleRacErrorData)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
//        print("initial line count: \(lines.count)")
        print("init lines element counts: \(lines.map{ $0.count })")
        scanner.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
//        XCTAssertEqual(lines.count, 4)
    }

    func testFindAndRepairLinesWithErrorsForFull1919raceFile() throws {
        let fileString = try String(contentsOfFile: AL1919racFilePath, encoding: .isoLatin1)
        let scanner = LineScanner()
        var lines = scanner.getLines(fromString: fileString)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
        print("file:\n\(fileString)")
        print("initial line count: \(lines.count)")
        print("init lines element counts: \(lines.map{ $0.count })")
        scanner.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
    }

    func testFindAndRepairLinesWithErrorsForFull919ptsShortFile() throws {
        let fileString = try String(contentsOfFile: AL919ptsShortFilePath, encoding: .isoLatin1)
        let scanner = LineScanner()
        var lines = scanner.getLines(fromString: fileString)
        let initLinesCount = lines.count
        let firstLineLength = lines.first!.count
        print("file:\n\(fileString)")
        print("initial line count: \(lines.count)")
        print("init lines element counts: \(lines.map{ $0.count })")
        scanner.findAndRepairLinesWithTooFewElements(&lines)
        print("final lines count: \(lines.count)")
        print("final lines element counts: \(lines.map{ $0.count })")
        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
        XCTAssertTrue(linesWithIncorrectLength.count == 0)
        XCTAssertNotEqual(initLinesCount, lines.count)
    }

    func testFindErrorsInDirectory() throws {
        let scanner = LineScanner()
        let fileManager = FileManager.default
        let directoryUrl = URL(fileURLWithPath: sampleDataDirPath, isDirectory: true)
        let enum1 = fileManager.enumerator(at: directoryUrl, 
                                           includingPropertiesForKeys: nil,
                                           options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        let items = enum1?.allObjects as! [URL]
        let csvItems = items.filter { $0.lastPathComponent.hasSuffix("csv") }
        print("csvItems.count: \(csvItems.count)")
//        print("csvItems:\n\(csvItems)")
        var initialFilesWithIssuesCount = 0
        var finalFilesWithIssuesCount = 0
        let fileErrors = try csvItems
            .map { csvFile -> (fileUrl: URL, issues: [(lineIndex: Int, lineCount: Int, targetColumnCount: Int)]) in
                return try autoreleasepool {
                    let fileString = try String(contentsOf: csvFile, encoding: .isoLatin1)
                    var lines = scanner.getLines(fromString: fileString)
                    let linesWithIssues = scanner.findLinesWithIncorrectElementCount(fromLines: lines)
                    if linesWithIssues.count > 0 {
                        initialFilesWithIssuesCount += 1
//                        print("\(csvFile) --> \(linesWithIssues)")
                        for issueLine in linesWithIssues {
                            if issueLine.lineCount > issueLine.targetColumnCount {
                            }
                            scanner.repairSequentialLines(lines: &lines,
                                                          firstLineIndex: issueLine.lineIndex,
                                                          targetColumnCount: issueLine.targetColumnCount)
                        }
                        lines.removeAll{ $0.count == 0 }
                        lines.removeAll { $0.count == 1 && $0.first!.isEmpty }
                        let linesWithIssuesAfterSequentialLineRepair = scanner.findLinesWithIncorrectElementCount(fromLines: lines)
                        if linesWithIssuesAfterSequentialLineRepair.count > 0 {
                            finalFilesWithIssuesCount += 1
                            print("\(csvFile) --> \(linesWithIssuesAfterSequentialLineRepair)")
                        }
                        return (fileUrl: csvFile, issues: linesWithIssuesAfterSequentialLineRepair)
                    }else{
                        return (fileUrl: csvFile, issues: linesWithIssues )
                    }
                }
            }
        let nonEmptyFileErrors = fileErrors.filter { $0.issues.count > 0 }
        let totalLinesWithErrors = nonEmptyFileErrors.reduce(into: []) { partialResult, fileIssues in
            partialResult.append(contentsOf: fileIssues.issues)
        }
        let linesWithTooManyElements = totalLinesWithErrors.filter { $0.lineCount > $0.targetColumnCount }
        print("files not solved with error correction:")
//        nonEmptyFileErrors.forEach { print("\($0.fileUrl) -> \($0.issues)") }
        print("found \(nonEmptyFileErrors.count) files with issues")
        print("found \(totalLinesWithErrors.count) lines with incorrect column counts")
        print("found \(linesWithTooManyElements.count) lines with too many columns")
        print("initialFilesWithIssuesCount: \(initialFilesWithIssuesCount)")
        print("finalFilesWithIssuesCount: \(finalFilesWithIssuesCount)")


//        nonEmptyFileErrors.forEach { fileWithIssues in
//            print("\(fileWithIssues.fileUrl) --> \(fileWithIssues.issues)")
//        }

//        let fileString = try String(contentsOfFile: AL919ptsShortFilePath, encoding: .isoLatin1)
//        let scanner = LineScanner()
//        var lines = scanner.getLines(fromString: fileString)
//        let initLinesCount = lines.count
//        let firstLineLength = lines.first!.count
//        print("file:\n\(fileString)")
//        print("initial line count: \(lines.count)")
//        print("init lines element counts: \(lines.map{ $0.count })")
//        scanner.findAndRepairLinesWithTooFewElements(&lines)
//        print("final lines count: \(lines.count)")
//        print("final lines element counts: \(lines.map{ $0.count })")
//        let linesWithIncorrectLength = lines.filter { $0.count != firstLineLength }
//        XCTAssertTrue(linesWithIncorrectLength.count == 0)
//        XCTAssertNotEqual(initLinesCount, lines.count)
    }

}
