import XCTest
import RegexBuilder
import Foundation
@testable import PSParse

final class PSParseV2Tests: XCTestCase {

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
    func testStandard1CharGenderCell() async throws {

    }
    func testCellWithTab() async throws {

    }
    func testSimpleHeaderLine() async throws {

    }
    func testHeaderLineV1() async throws {
//        let sampleAL1919racHeader = """
//        Raceid	Eventid	Seasoncode	Racecodex	Disciplineid	Disciplinecode	Catcode	Catcode2	Catcode3	Catcode4	Gender	Racedate	Starteventdate	Description	Place	Nationcode	Td1id	Td1name	Td1nation	Td1code	Td2id	Td2name	Td2nation	Td2code	Calstatuscode	Procstatuscode	Receiveddate	Pursuit	Masse	Relay	Distance	Hill	Style	Qualif	Finale	Homol	Webcomment	Displaystatus	Fisinterncomment	Published	Validforfispoints	Usedfislist	Tolist	Discforlistcode	Calculatedpenalty	Appliedpenalty	Appliedscala	Penscafixed	Version	Nationraceid	Provraceid	Msql7evid	Mssql7id	Results	Pdf	Topbanner	Bottombanner	Toplogo	Bottomlogo	Gallery	Indi	Team	Tabcount	Columncount	Level	Hloc1	Hloc2	Hloc3	Hcet1	Hcet2	Hcet3	Live	Livestatus1	Livestatus2	Livestatus3	Liveinfo1	Liveinfo2	Liveinfo3	Passwd	Timinglogo	validdate	TDdoc	Timingreport	Special_cup_points	Skip_wcsl	Lastupdate
//        """
//        let sampleAL1919resHeader = """
//        Recid	Raceid	Competitorid	Status	Status2	Position	Bib	Fiscode	Competitorname	Nationcode	Timer1	Timer2	Timer3	Timetot	Valid	Racepoints	Cuppoints	Version	Timer1int	Timer2int	Timer3int	Timetotint	Racepointsreceived	Listfispoints	Ptsmax	Lastupdate
//
//        """
//        let sampleAL1919teamHeader = """
//        Competitorid	Sectorcode	Fiscode	Lastname	Firstname	Gender	Birthdate	Nationcode	Nationalcode	Skiclub	Association	Status	Status_old
//        """
//        let sampleAL1919ptsHeader = """
//        Recid	Listid	Competitorid	Disciplinecode	Fispoints	Position	Penalty	Active	Avenumresults	Fixedbyfis	Raceid1	Raceid2	Raceid3	Version	Pointspreviouslist	pourcentpreviouslist	Countlistsamestatus	pourcent	Realpoints	blessevalide	Youthpoints	Lastupdate
//        """
//        let sampleAL1919hdrHeader = """
//        Listalid	Listid	Seasoncode	Listnumber	Listname	Speciallist	Printdeadline	Calculationdate	Startracedate	Endracedate	Validfrom	Validto	Published	Version	Lastupdate
//        """
//        let sampleAL1919evtHeader = """
//        Eventid	Seasoncode	Sectorcode	Eventname	Startdate	Enddate	Nationcodeplace	Orgnationcode	Place	Published	OrgaddressL1	OrgaddressL2	OrgaddressL3	OrgaddressL4	Orgtel	Orgmobile	Orgfax	OrgEmail	Orgemailentries	Orgemailaccomodation	Orgemailtransportation	OrgWebsite	Socialmedia	Eventnotes	Languageused	Td1id	Td1name	Td1nation	Td2id	Td2name	Td2nation	Orgfee	Bill	Billdate	Selcat	Seldis	Seldisl	Seldism	Dispdate	Discomment	Version	Nationeventid	Proveventid	Mssql7id	Results	Pdf	Topbanner	Bottombanner	Toplogo	Bottomlogo	Gallery	Nextracedate	Lastracedate	TDletter	Orgaddressid	Tournament	Parenteventid	Placeid	Lastupdate
//        """
//        let sampleAL1919disHeader = """
//        Recid	Listid	Seasoncode	Disciplinecode	Gender	Xvalue	Yvalue	Zvalue	Minpenalty	Maxpenalty	Fvalue	Maxpoints	Injuryminpen	Injurymaxpen	Injurypercentage	Version	Adder0	Adder1	Adder2	Adder3	Adder4	Adder5	Adder6	Lastupdate
//        """
//        let sampleAL1919comHeader = """
//        Competitorid	Sectorcode	Fiscode	Lastname	Firstname	Gender	Birthdate	Nationcode	Nationalcode	Skiclub	Association	Status	Status_old
//        """
//        let sampleAL1919catHeader = """
//        Recid	Listid	Seasoncode	Catcode	Gender	Minfispoints	Maxfispoints	Adder	Version	Lastupdate
//        """
    }
    func testFirstDataLineV1() async throws {

    }
    func testFirstTwoLinesV1() async throws {

    }
    func testCellWithExtraneousNewLine() async throws {
        let sampleRacErrorData = """
96221	44733	2019	6550	0	SL	NJR				L	2019-01-05	2019-01-04	Slalom	Passo Monte Croce Comelico	ITA	111532	Vicenzi Enrico (ITA)	ITA	0					R	V									0	11070/11/13	Replaces: Val di Zoldo			1	1	275	276		45.01	45.01		0	0	500000				1	0						0	0	0	0																	2019-01-06	1	1	0	0	2019-01-21 20:50:15
        96226	43636	2019	249	0	GS	FIS				M	2019-03-14	2019-03-12	Giant Slalom	Squaw Valley	USA	101182	Perricone Roger (USA)	USA						R	V										11852/11/15.
            Replaces: Alyeska Resort			1	1	280	281		35.51	35.51		0	0	500000				1	0						0	0	0	0																	2019-03-14	1	1	0	0	2019-03-19 09:08:07
        96227	43636	2019	5231	0	SL	FIS				L	2019-03-14	2019-03-12	Slalom	Alpine Meadows	USA	100656	Mahre Paul F. (USA)	USA						R	V									0	11852/11/15.
            Replaces: Alyeska Resort			1	1	280	281		57.98	57.98		0	0	500000				1	0						0	0	0	0																	2019-03-15	1	1	0	0	2019-03-19 09:08:07
        96228	43636	2019	250	0	SL	FIS				M	2019-03-17	2019-03-12	Slalom	Alpine Meadows	USA	100656	Mahre Paul F. (USA)	USA						R	V									0		Replaces: Alyeska Resort			1	1	280	281		40	40		0	0	500000				1	0						0	0	0	0																	2019-03-17	1	1	0	0	2019-03-19 09:08:07
        96229	43636	2019	5234	0	GS	FIS				L	2019-03-17	2019-03-12	Giant Slalom	Squaw Valley	USA	101182	Perricone Roger (USA)	USA						R	V									0		Replaces: Alyeska Resort			1	1	280	281		61.32	61.32		0	0	500000				1	0						0	0	0	0																	2019-03-17	1	1	0	0	2019-03-19 09:08:07
"""
    }
    func testItemWithExtraTabV1() async throws {

    }
    func testGetLinesV1() async throws {

    }
}
