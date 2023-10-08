//
//  File.swift
//  
//
//  Created by Justin on 9/4/23.
//

import Foundation

let dateSpaceTimeFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
    return formatter
}()

let dateWithDashesFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

enum FieldType: Equatable, Hashable {
    case integer(nullable: Bool, expectedValue: Int?, expectedLength: Int?)
    case float(nullable: Bool)
    case string(nullable: Bool, expectedLength: Int?, startsWith: String?, contains: String?)
    case unknownString
    case date(nullable: Bool)
    case dateTime
    case empty
}

extension FieldType {
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
        case .unknownString:
            return .unknownString
        case .date:
            return dateWithDashesFormatter.date(from: input) != nil ? .valid : .invalid
        case .dateTime:
            return dateSpaceTimeFormatter.date(from: input) != nil ? .valid : .invalid
        case .empty:
            return input.isEmpty ? .valid : .invalid
        }
    }
}

extension FieldType {
    static let eventFieldNameToTypes: [String : FieldType] = [
        "Eventid": .integer(nullable: false, expectedValue: nil, expectedLength: nil), //Eventid
        "Seasoncode": .integer(nullable: false, expectedValue: nil, expectedLength: 4), //Seasoncode
        "Sectorcode": .string(nullable: false, expectedLength: 2, startsWith: nil, contains: nil), //Sectorcode
        "Eventname": .unknownString, //Eventname
        "Startdate": .date(nullable: false), //Startdate
        "Enddate": .date(nullable: false), //Enddate
        "Nationcodeplace": .string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil), //Nationcodeplace
        "Orgnationcode": .string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil), // Orgnationcode
        "Place": .unknownString, //Place
        "Published": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Published
        "OrgaddressL1": .unknownString, //OrgaddressL1
        "OrgaddressL2": .unknownString, //OrgaddressL2
        "OrgaddressL3": .unknownString, //OrgaddressL3
        "OrgaddressL4": .unknownString, //OrgaddressL4
        "Orgtel": .unknownString, //Orgtel
        "Orgmobile": .unknownString, //Orgmobile
        "Orgfax": .unknownString, //Orgfax
        "OrgEmail": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //OrgEmail
        "OrgEntryEmail": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"),
        "Orgemailentries": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailentries
        "Orgemailaccomodation": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailaccomodation
        "Orgemailtransportation": .string(nullable: false, expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailtransportation
        "OrgWebsite": .unknownString, //OrgWebsite
        "Socialmedia": .unknownString, //Socialmedia
        "Eventnotes": .unknownString, //Eventnotes
        "Languageused": .unknownString, //Languageused
        "Td1id": .unknownString, //Td1id
        "Td1name": .unknownString, //Td1name
        "Td1nation": .unknownString, //Td1nation
        "Td2id": .unknownString, //Td2id
        "Td2name": .unknownString, //Td2name
        "Td2nation": .unknownString, //Td2nation
        "Orgfee": .unknownString, //Orgfee
        "Bill": .unknownString, //Bill
        "Billdate": .unknownString, //Billdate
        "Selcat": .string(nullable: false, expectedLength: nil, startsWith: "-", contains: nil), //Selcat
        "Seldis": .string(nullable: false, expectedLength: nil, startsWith: "-", contains: nil), //Seldis
        "Seldisl": .unknownString, //Seldisl
        "Seldism": .unknownString, //Seldism
        "Dispdate": .unknownString, //Dispdate
        "Discomment": .unknownString, //Discomment
        "Version": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Version,
        "Nationeventid": .unknownString, //Nationeventid
        "Proveventid": .unknownString, //Proveventid
        "Mssql7id": .unknownString, //Mssql7id
        "Results": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Results
        "Pdf": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Pdf
        "Topbanner": .unknownString, //Topbanner
        "Bottombanner": .unknownString, //Bottombanner
        "Toplogo": .unknownString, //Toplogo
        "Bottomlogo": .unknownString, //Bottomlogo
        "Gallery": .unknownString, //Gallery
        "Nextracedate": .unknownString, //Nextracedate
        "Lastracedate": .unknownString, //Lastracedate
        "TDletter": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //TDletter
        "Orgaddressid": .unknownString, //Orgaddressid
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
        "Disciplinecode": .unknownString,
        "Catcode": .unknownString,
        "Catcode2": .unknownString,
        "Catcode3": .unknownString,
        "Catcode4": .unknownString,
        "Gender": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Racedate": .date(nullable: false),
        "Starteventdate": .date(nullable: false),
        "Description": .unknownString,
        "Place": .unknownString,
        "Nationcode": .string(nullable: false, expectedLength: 3, startsWith: nil, contains: nil),
        "Td1id": .integer(nullable: true, expectedValue: nil, expectedLength: nil),
        "Td1name": .unknownString,
        "Td1nation": .unknownString,
        "Td1code": .unknownString,
        "Td2id": .unknownString,
        "Td2name": .unknownString,
        "Td2nation": .unknownString,
        "Td2code": .unknownString,
        "Calstatuscode": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil), // could be an enum
        "Procstatuscode": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil), // could be an enum
        "Receiveddate": .empty,
        "Pursuit": .empty,
        "Masse": .empty,
        "Relay": .empty,
        "Distance": .empty,
        "Hill": .empty,
        "Style": .unknownString,
        "Qualif": .empty,
        "Finale": .unknownString,
        "Homol": .unknownString,
        "Webcomment": .unknownString,
        "Displaystatus": .unknownString,
        "Fisinterncomment": .unknownString,
        "Published": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Validforfispoints": .string(nullable: false, expectedLength: 1, startsWith: nil, contains: nil),
        "Usedfislist": .unknownString,
        "Tolist": .unknownString,
        "Discforlistcode": .empty,
        "Calculatedpenalty": .float(nullable: true),
        "Appliedpenalty": .float(nullable: true),
        "Appliedscala": .empty,
        "Penscafixed": .integer(nullable: true, expectedValue: 0, expectedLength: nil),
        "Version": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Nationraceid": .unknownString,
        "Provraceid": .empty,
        "Msql7evid": .empty,
        "Mssql7id": .empty,
        "Results": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Pdf": .integer(nullable: false, expectedValue: nil, expectedLength: 1),
        "Topbanner": .unknownString,
        "Bottombanner": .unknownString,
        "Toplogo": .unknownString,
        "Bottomlogo": .unknownString,
        "Gallery": .unknownString,
        "Indi": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Team": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Tabcount": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Columncount": .integer(nullable: false, expectedValue: 0, expectedLength: nil),
        "Level": .unknownString,
        "Hloc1": .unknownString,
        "Hloc2": .unknownString,
        "Hloc3": .unknownString,
        "Hcet1": .unknownString,
        "Hcet2": .unknownString,
        "Hcet3": .unknownString,
        "Live": .integer(nullable: true, expectedValue: nil, expectedLength: 1),
        "Livestatus": .unknownString,
        "Livestatus1": .unknownString,
        "Livestatus2": .unknownString,
        "Livestatus3": .unknownString,
        "Liveinfo": .unknownString,
        "Liveinfo1": .unknownString,
        "Liveinfo2": .unknownString,
        "Liveinfo3": .unknownString,
        "Passwd": .unknownString,
        "Timinglogo": .unknownString,
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
    //TODO: make these real
    static let raceResultFieldNameToTypes: [String : FieldType] = [
        "Timer3int": .unknownString,
        "Ptsmax": .unknownString,
        "Status2": .unknownString,
        "Version": .unknownString,
        "Timer1": .unknownString,
        "Status": .unknownString,
        "Cuppoints": .unknownString,
        "Timer1int": .unknownString,
        "Recid": .unknownString,
        "Fiscode": .unknownString,
        "Timer2int": .unknownString,
        "Bib": .unknownString,
        "Racepoints": .unknownString,
        "Heat": .unknownString,
        "Nationcode": .unknownString,
        "Timetotint": .unknownString,
        "Raceid": .unknownString,
        "Reason": .unknownString,
        "Competitorid": .unknownString,
        "Competitorname": .unknownString,
        "Timer2": .unknownString,
        "Position": .unknownString,
        "Level": .unknownString,
        "Listfispoints": .unknownString,
        "Timetot": .unknownString,
        "Racepointsreceived": .unknownString,
        "Lastupdate": .unknownString,
        "Timer3": .unknownString,
        "Valid": .unknownString
    ]
    static let athleteFieldNameToTypes: [String : FieldType] = [
        "Nationalcode": .unknownString,
        "Skiclub": .unknownString,
        "Competitorid": .unknownString,
        "Status_old": .unknownString,
        "Lastname": .unknownString,
        "Gender": .unknownString,
        "Statusnextlist": .unknownString,
        "Status": .unknownString,
        "Gender_2021": .unknownString,
        "Nationcode": .unknownString,
        "Fiscode": .unknownString,
        "Firstname": .unknownString,
        "Sectorcode": .unknownString,
        "Association": .unknownString,
        "Birthdate": .unknownString
    ]
    static let pointsFieldNameToTypes: [String : FieldType] = [
        "Active": .unknownString,
        "Avenumresults": .unknownString,
        "Realpoints": .unknownString,
        "Fixedbyfis": .unknownString,
        "blessevalide": .unknownString,
        "Version": .unknownString,
        "pourcentpreviouslist": .unknownString,
        "Raceid3": .unknownString,
        "Seasoncode": .unknownString,
        "Recid": .unknownString,
        "Position": .unknownString,
        "Raceid2": .unknownString,
        "Basepoints": .unknownString,
        "Competitorid": .unknownString,
        "Penalty": .unknownString,
        "Disciplinecode": .unknownString,
        "Pointspreviouslist": .unknownString,
        "Fispoints": .unknownString,
        "Countlistsamestatus": .unknownString,
        "Lastupdate": .unknownString,
        "Raceid1": .unknownString,
        "Listid": .unknownString,
        "Youthpoints": .unknownString,
        "pourcent": .unknownString
    ]
    static let catFieldNameToTypes: [String : FieldType] = [
        "Minfispoints": .unknownString,
        "Gender": .unknownString,
        "Version": .unknownString,
        "Adder": .unknownString,
        "Lastupdate": .unknownString,
        "Seasoncode": .unknownString,
        "Listid": .unknownString,
        "Recid": .unknownString,
        "Maxfispoints": .unknownString,
        "Catcode": .unknownString
    ]
    static let hdrFieldNameToTypes: [String : FieldType] = [
        "Listalid": .unknownString,
        "Speciallist": .unknownString,
        "Listid": .unknownString,
        "Calculationdate": .unknownString,
        "Startracedate": .unknownString,
        "Seasoncode": .unknownString,
        "Validto": .unknownString,
        "Listnumber": .unknownString,
        "Published": .unknownString,
        "Endracedate": .unknownString,
        "Lastupdate": .unknownString,
        "Validfrom": .unknownString,
        "Printdeadline": .unknownString,
        "Recid": .unknownString,
        "Listname": .unknownString,
        "Version": .unknownString
    ]
    static let disFieldNameToTypes: [String : FieldType] = [
        "Injurymaxpen": .unknownString,
        "Fvalue": .unknownString,
        "Adder1": .unknownString,
        "Gender": .unknownString,
        "Adder0": .unknownString,
        "Listid": .unknownString,
        "Seasoncode": .unknownString,
        "Minpenalty": .unknownString,
        "Disciplinecode": .unknownString,
        "Injuryminpen": .unknownString,
        "Adder3": .unknownString,
        "Xvalue": .unknownString,
        "Adder4": .unknownString,
        "Maxpenalty": .unknownString,
        "Adder5": .unknownString,
        "Zvalue": .unknownString,
        "Yvalue": .unknownString,
        "Maxpoints": .unknownString,
        "Adder6": .unknownString,
        "Version": .unknownString,
        "Injurypercentage": .unknownString,
        "Adder2": .unknownString,
        "Recid": .unknownString,
        "Lastupdate": .unknownString
    ]
}

enum ValidationResult {
    case valid
    case null
    case unknownString
    case invalid
}
