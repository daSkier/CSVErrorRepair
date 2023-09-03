//
//  File.swift
//  
//
//  Created by Justin on 6/8/23.
//

import Foundation
import RegexBuilder

enum RaceRegexComponent: String {
    case raceId = "Raceid"
    case eventId = "Eventid"
    case seasonCode = "Seasoncode"
    case raceCodex = "Racecodex"
    case disciplineId = "Disciplineid"
    case disciplineCode = "Disciplinecode"
    case catCode = "Catcode"
    case catCode2 = "Catcode2"
    case catCode3 = "Catcode3"
    case catCode4 = "Catcode4"
    case gender = "Gender"
    case raceDate = "Racedate"
    case startEventDate = "Starteventdate"
    case description = "Description"
    case place = "Place"
    case nationcode = "Nationcode"
    case td1Id = "Td1id"
    case td1Name = "Td1name"
    case td1Nation = "Td1nation"
    case td1Code = "Td1code"
    case td2Id = "Td2id"
    case td2Name = "Td2name"
    case td2Nation = "Td2nation"
    case td2Code = "Td2code"
    case calStatusCode = "Calstatuscode"
    case procStatusCode = "Procstatuscode"
    case receivedDate = "Receiveddate"
    case pursuit = "Pursuit"
    case masse = "Masse"
    case relay = "Relay"
    case distance = "Distance"
    case hill = "Hill"
    case style = "Style"
    case qualif = "Qualif"
    case finale = "Finale"
    case homol = "Homol"
    case webComment = "Webcomment"
    case displayStatus = "Displaystatus"
    case fisInternComment = "Fisinterncomment"
    case published = "Published"
    case validForFisPoints = "Validforfispoints"
    case usedFisList = "Usedfislist"
    case toList = "Tolist"
    case discForListCode = "Discforlistcode"
    case calculatedPenalty = "Calculatedpenalty"
    case appliedPenalty = "Appliedpenalty"
    case appliedScala = "Appliedscala"
    case penscaFixed = "Penscafixed"
    case version = "Version"
    case nationRaceId = "Nationraceid"
    case provRaceId = "Provraceid"
    case msql7evid = "Msql7evid"
    case mssql7id = "Mssql7id"
    case results = "Results"
    case pdf = "Pdf"
    case topBanner = "Topbanner"
    case bottomBanner = "Bottombanner"
    case topLogo = "Toplogo"
    case bottomLogo = "Bottomlogo"
    case gallery = "Gallery"
    case indi = "Indi"
    case team = "Team"
    case tabCount = "Tabcount"
    case columnCount = "Columncount"
    case level = "Level"
    case hLoc1 = "Hloc1"
    case hLoc2 = "Hloc2"
    case hLoc3 = "Hloc3"
    case hCet1 = "Hcet1"
    case hCet2 = "Hcet2"
    case hCet3 = "Hcet3"
    case live = "Live"
    case liveStatus1 = "Livestatus1"
    case liveStatus2 = "Livestatus2"
    case liveStatus3 = "Livestatus3"
    case liveInfo1 = "Liveinfo1"
    case liveInfo2 = "Liveinfo2"
    case liveInfo3 = "Liveinfo3"
    case passwd = "Passwd"
    case timingLogo = "Timinglogo"
    case validDate = "validdate"
    case tdDoc = "TDdoc"
    case timingReport = "Timingreport"
    case specialCupPoints = "Special_cup_points"
    case skipWcsl = "Skip_wcsl"
    case lastUpdate = "Lastupdate"

    var regex: any RegexComponent {
        let enUSLocale = Locale(languageCode: .english, languageRegion: .unitedStates)
        return switch self {
        case .raceId:
                .localizedInteger(locale: enUSLocale)
        case .eventId:
                .localizedInteger(locale: enUSLocale)
        case .seasonCode:
                .localizedInteger(locale: enUSLocale)
        case .raceCodex:
                .localizedInteger(locale: enUSLocale)
        case .disciplineId:
            One(.digit)
        case .disciplineCode:
            Repeat(.word, count: 2)
        case .catCode:
            OneOrMore{
                .word
            }
        case .catCode2:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .catCode3:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .catCode4:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .gender:
            One(.word)
        case .raceDate:
            One(
                .iso8601Date(timeZone: TimeZone(identifier: "UTC")!, dateSeparator: .dash)
            )
        case .startEventDate:
            One(
                .iso8601Date(timeZone: TimeZone(identifier: "UTC")!, dateSeparator: .dash)
            )
        case .description:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .place:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .nationcode:
            Repeat(count: 3) {
                .any.subtracting(.anyOf("\t\n"))
            }
        case .td1Id:
            One(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .td1Name:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .td1Nation:
            Repeat(count: 3) {
                .any.subtracting(.anyOf("\t\n"))
            }
        case .td1Code:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .td2Id:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .td2Name:
            Optionally(
                ZeroOrMore{
                    .any.subtracting(.anyOf("\t\n"))
                }
            )
        case .td2Nation:
            Optionally(
                Repeat(count: 3) {
                    .any.subtracting(.anyOf("\t\n"))
                }
            )
        case .td2Code:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .calStatusCode:
            One(
                .any.subtracting(.anyOf("\t\n"))
            )
        case .procStatusCode:
            One(
                .any.subtracting(.anyOf("0123456789\t\n"))
            )
        case .receivedDate:
            Optionally(
                One(
                    .iso8601Date(timeZone: TimeZone(identifier: "UTC")!, dateSeparator: .dash)
                )
            )
        case .pursuit:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .masse:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .relay:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .distance:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hill:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .style:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .qualif:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .finale:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .homol:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .webComment:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .displayStatus:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .fisInternComment:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .published:
            Optionally(
                One(
                    .localizedInteger(locale: Locale(identifier: "en_US"))
                )
            )
        case .validForFisPoints:
            Optionally(
                One(
                    .localizedInteger(locale: Locale(identifier: "en_US"))
                )
            )
        case .usedFisList:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .toList:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .discForListCode:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .calculatedPenalty:
            Optionally(
                .localizedDouble(locale: Locale(identifier: "en_US"))
            )
        case .appliedPenalty:
            Optionally(
                .localizedDouble(locale: Locale(identifier: "en_US"))
            )
        case .appliedScala:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .penscaFixed:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .version:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .nationRaceId:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .provRaceId:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .msql7evid:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .mssql7id:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .results:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .pdf:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .topBanner:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .bottomBanner:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .topLogo:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .bottomLogo:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .gallery:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .indi:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .team:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .tabCount:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .columnCount:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .level:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hLoc1:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hLoc2:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hLoc3:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hCet1:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hCet2:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .hCet3:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .live:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .liveStatus1:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .liveStatus2:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .liveStatus3:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .liveInfo1:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .liveInfo2:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .liveInfo3:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .passwd:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .timingLogo:
            ZeroOrMore{
                .any.subtracting(.anyOf("\t\n"))
            }
        case .validDate:
            One(
                .iso8601Date(timeZone: TimeZone(identifier: "UTC")!, dateSeparator: .dash)
            )
        case .tdDoc:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .timingReport:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .specialCupPoints:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .skipWcsl:
            Optionally(
                .localizedInteger(locale: Locale(identifier: "en_US"))
            )
        case .lastUpdate:
            One(
                .iso8601(timeZone: TimeZone(identifier: "UTC")!,
                         includingFractionalSeconds: false,
                         dateSeparator: .dash,
                         dateTimeSeparator: .space,
                         timeSeparator: .colon)
            )
        }
    }
}
