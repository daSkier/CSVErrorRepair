import XCTest
import RegexBuilder
import Foundation
@testable import PSParse

final class PSParseTests: XCTestCase {

    let enUSLocale = Locale(languageCode: .english, languageRegion: .unitedStates)

    let standardStringCellRegex = Regex{
        OneOrMore{
            .any.subtracting(.anyOf("\t\n"))
        }
//        Optionally {
//            ChoiceOf{
//                "\t"
//                "\n"
//                "\r"
//            }
//        }
    }

    let standardIntegerCellRegex = Regex{
        .localizedInteger(locale: Locale(languageCode: .english, languageRegion: .unitedStates))
    }

    let standardDecimalCellRegex = Regex{
        .localizedDecimal(locale: Locale(languageCode: .english, languageRegion: .unitedStates))
    }

    let standardDoubleCellRegex = Regex{
        .localizedDouble(locale: Locale(languageCode: .english, languageRegion: .unitedStates))
    }

    let standardDateTimeRegex = Regex {
        .iso8601(timeZone: TimeZone(identifier: "UTC")!,
                 includingFractionalSeconds: false,
                 dateSeparator: .dash,
                 dateTimeSeparator: .space,
                 timeSeparator: .colon)
    }

    let standardDateRegex = Regex {
        .iso8601Date(timeZone: TimeZone(identifier: "UTC")!, dateSeparator: .dash)
    }

    let standard3CharRegex = Regex {
        Repeat(count: 3) {
            .any.subtracting(.anyOf("\t\n"))
        }
    }

    let standard2CharRegex = Regex {
        Repeat(count: 2) {
            .any.subtracting(.anyOf("\t\n"))
        }
    }

    let standard1CharRegex = Regex {
        Repeat(count: 1) {
            .any.subtracting(.anyOf("\t\n"))
        }
    }

    func testStandardStringCell() async throws {
        let stringEOL = "hello world"
        let stringFollowedByTab = "hello world\t"
        let stringFollowedByNewLine = "hello world\n"

        let results1 = stringEOL.matches(of: standardStringCellRegex)
        print("stringEOL: \(results1.map{ $0.output })")
        let results2 = stringFollowedByTab.matches(of: standardStringCellRegex)
        print("stringFollowedByTab: \(results2.map{ $0.output })")
        let results3 = stringFollowedByNewLine.matches(of: standardStringCellRegex)
        print("stringFollowedByNewLine: \(results3.map{ $0.output })")
    }

    func testStandardIntegerCell() async throws {
        let integerEOL = "1"
        let integerFollowedByTab = "1\t"
        let integerFollowedByNewLine = "1\n"

        let results1 = integerEOL.matches(of: standardIntegerCellRegex)
        print("integerEOL: \(results1.map{ $0.output })")
        let results2 = integerFollowedByTab.matches(of: standardIntegerCellRegex)
        print("integerFollowedByTab: \(results2.map{ $0.output })")
        let results3 = integerFollowedByNewLine.matches(of: standardIntegerCellRegex)
        print("integerFollowedByNewLine: \(results3.map{ $0.output })")
    }
    func testStandardDecimalCell() async throws {
        let decimalEOL = "23.01"
        let decimalFollowedByTab = "23.01\t"
        let decimalFollowedByNewLine = "23.01\n"

        let results1 = decimalEOL.matches(of: standardDecimalCellRegex)
        print("decimalEOL: \(results1.map{ $0.output })")
        let results2 = decimalFollowedByTab.matches(of: standardDecimalCellRegex)
        print("decimalFollowedByTab: \(results2.map{ $0.output })")
        let results3 = decimalFollowedByNewLine.matches(of: standardDecimalCellRegex)
        print("decimalFollowedByNewLine: \(results3.map{ $0.output })")
    }

    func testStandardDoubleCell() async throws {
        let doubleEOL = "23.01"
        let doubleFollowedByTab = "23.01\t"
        let doubleFollowedByNewLine = "23.01\n"

        let results1 = doubleEOL.matches(of: standardDoubleCellRegex)
        print("doubleEOL: \(results1.map{ $0.output })")
        let results2 = doubleFollowedByTab.matches(of: standardDoubleCellRegex)
        print("doubleFollowedByTab: \(results2.map{ $0.output })")
        let results3 = doubleFollowedByNewLine.matches(of: standardDoubleCellRegex)
        print("doubleFollowedByNewLine: \(results3.map{ $0.output })")
    }

    func testStandardDateTimeCell() async throws {
        let dateTimeEOL = "2018-09-06 08:28:03"
        let dateTimeFollowedByTab = "2018-09-06 08:28:03\t"
        let dateTimeFollowedByNewLine = "2018-09-06 08:28:03\n"

        let results1 = dateTimeEOL.matches(of: standardDateTimeRegex)
        print("dateTimeEOL: \(results1.map{ $0.output })")
        let results2 = dateTimeFollowedByTab.matches(of: standardDateTimeRegex)
        print("dateTimeFollowedByTab: \(results2.map{ $0.output })")
        let results3 = dateTimeFollowedByNewLine.matches(of: standardDateTimeRegex)
        print("dateTimeFollowedByNewLine: \(results3.map{ $0.output })")
    }
    func testStandardDateCell() async throws {
        let dateEOL = "2018-09-06 08:28:03"
        let dateFollowedByTab = "2018-09-06 08:28:03\t"
        let dateFollowedByNewLine = "2018-09-06 08:28:03\n"

        let results1 = dateEOL.matches(of: standardDateRegex)
        print("dateEOL: \(results1.map{ $0.output })")
        let results2 = dateFollowedByTab.matches(of: standardDateRegex)
        print("dateFollowedByTab: \(results2.map{ $0.output })")
        let results3 = dateFollowedByNewLine.matches(of: standardDateRegex)
        print("dateFollowedByNewLine: \(results3.map{ $0.output })")
    }
    func testStandard2CharCell() async throws {
        let twoCharEOL = "US"
        let twoCharFollowedByTab = "US\t"
        let twoCharFollowedByNewLine = "US\n"

        let results1 = twoCharEOL.matches(of: standard2CharRegex)
        print("twoCharEOL: \(results1.map{ $0.output })")
        let results2 = twoCharFollowedByTab.matches(of: standard2CharRegex)
        print("twoCharFollowedByTab: \(results2.map{ $0.output })")
        let results3 = twoCharFollowedByNewLine.matches(of: standard2CharRegex)
        print("twoCharFollowedByNewLine: \(results3.map{ $0.output })")
    }
    func testStandard3CharCell() async throws {
        let threeCharEOL = "USA"
        let threeCharFollowedByTab = "USA\t"
        let threeCharFollowedByNewLine = "USA\n"

        let results1 = threeCharEOL.matches(of: standard3CharRegex)
        print("threeCharEOL: \(results1.map{ $0.output })")
        let results2 = threeCharFollowedByTab.matches(of: standard3CharRegex)
        print("threeCharFollowedByTab: \(results2.map{ $0.output })")
        let results3 = threeCharFollowedByNewLine.matches(of: standard3CharRegex)
        print("threeCharFollowedByNewLine: \(results3.map{ $0.output })")
    }
    func testStandard1CharCell() async throws {
        let oneCharEOL = "U"
        let oneCharFollowedByTab = "U\t"
        let oneCharFollowedByNewLine = "U\n"

        let results1 = oneCharEOL.matches(of: standard1CharRegex)
        print("oneCharEOL: \(results1.map{ $0.output })")
        let results2 = oneCharFollowedByTab.matches(of: standard1CharRegex)
        print("oneCharFollowedByTab: \(results2.map{ $0.output })")
        let results3 = oneCharFollowedByNewLine.matches(of: standard1CharRegex)
        print("oneCharFollowedByNewLine: \(results3.map{ $0.output })")
    }
    func testHeaderLineV1() async throws {
        let headerRegex = Regex {
            Anchor.startOfLine
            OneOrMore {
                Capture {
                    .any.subtracting(.anyOf("\t\n"))
                    Optionally {
                        "\t"
                    }
                }

            }
            Anchor.endOfLine
        }
        let sampleAL1919racHeader = """
        Raceid	Eventid	Seasoncode	Racecodex	Disciplineid	Disciplinecode	Catcode	Catcode2	Catcode3	Catcode4	Gender	Racedate	Starteventdate	Description	Place	Nationcode	Td1id	Td1name	Td1nation	Td1code	Td2id	Td2name	Td2nation	Td2code	Calstatuscode	Procstatuscode	Receiveddate	Pursuit	Masse	Relay	Distance	Hill	Style	Qualif	Finale	Homol	Webcomment	Displaystatus	Fisinterncomment	Published	Validforfispoints	Usedfislist	Tolist	Discforlistcode	Calculatedpenalty	Appliedpenalty	Appliedscala	Penscafixed	Version	Nationraceid	Provraceid	Msql7evid	Mssql7id	Results	Pdf	Topbanner	Bottombanner	Toplogo	Bottomlogo	Gallery	Indi	Team	Tabcount	Columncount	Level	Hloc1	Hloc2	Hloc3	Hcet1	Hcet2	Hcet3	Live	Livestatus1	Livestatus2	Livestatus3	Liveinfo1	Liveinfo2	Liveinfo3	Passwd	Timinglogo	validdate	TDdoc	Timingreport	Special_cup_points	Skip_wcsl	Lastupdate

        """
        let racHeaderResults = sampleAL1919racHeader.matches(of: headerRegex)
        print("raceHeader: \(racHeaderResults.map{$0.output})")
        let matches = try! headerRegex.wholeMatch(in: sampleAL1919racHeader)
        print("match output \(String(describing: matches?.1))")
    }
    func testFirstDataLineV1() async throws {

    }
    func testFirstTwoLinesV1() async throws {
        let _ = """
        Raceid	Eventid	Seasoncode	Racecodex	Disciplineid	Disciplinecode	Catcode	Catcode2	Catcode3	Catcode4	Gender	Racedate	Starteventdate	Description	Place	Nationcode	Td1id	Td1name	Td1nation	Td1code	Td2id	Td2name	Td2nation	Td2code	Calstatuscode	Procstatuscode	Receiveddate	Pursuit	Masse	Relay	Distance	Hill	Style	Qualif	Finale	Homol	Webcomment	Displaystatus	Fisinterncomment	Published	Validforfispoints	Usedfislist	Tolist	Discforlistcode	Calculatedpenalty	Appliedpenalty	Appliedscala	Penscafixed	Version	Nationraceid	Provraceid	Msql7evid	Mssql7id	Results	Pdf	Topbanner	Bottombanner	Toplogo	Bottomlogo	Gallery	Indi	Team	Tabcount	Columncount	Level	Hloc1	Hloc2	Hloc3	Hcet1	Hcet2	Hcet3	Live	Livestatus1	Livestatus2	Livestatus3	Liveinfo1	Liveinfo2	Liveinfo3	Passwd	Timinglogo	validdate	TDdoc	Timingreport	Special_cup_points	Skip_wcsl	Lastupdate
        95332	42845	2019	5159	0	GS	SAC				L	2018-09-01	2018-09-01	Giant Slalom	El Colorado	CHI	101144	Quiroga Eduardo (ARG)	ARG						N	V										10949/05/13				1	1	267	268		12.04	12.04		0	0	500000				1	0						0	0	0	0		10:15	12:15		15:15	17:15		1									2018-09-02	1	1	0	0	2018-09-06 08:28:03

        """
    }
    func testGetLinesV1() async throws {

    }
}
