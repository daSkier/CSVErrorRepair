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

}
