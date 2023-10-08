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
    case float
    case string(expectedLength: Int?, startsWith: String?, contains: String?)
    case unknownString
    case date
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
        case .float:
            return Float(input) != nil ? .valid : .invalid
        case .string(let expectedLength, let startsWith, let contains):
            if let expectedLength {
                return input.count == expectedLength ? .valid : .invalid
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
        "Sectorcode": .string(expectedLength: 2, startsWith: nil, contains: nil), //Sectorcode
        "Eventname": .unknownString, //Eventname
        "Startdate": .date, //Startdate
        "Enddate": .date, //Enddate
        "Nationcodeplace": .string(expectedLength: 3, startsWith: nil, contains: nil), //Nationcodeplace
        "Orgnationcode": .string(expectedLength: 3, startsWith: nil, contains: nil), // Orgnationcode
        "Place": .unknownString, //Place
        "Published": .integer(nullable: false, expectedValue: nil, expectedLength: 1), //Published
        "OrgaddressL1": .unknownString, //OrgaddressL1
        "OrgaddressL2": .unknownString, //OrgaddressL2
        "OrgaddressL3": .unknownString, //OrgaddressL3
        "OrgaddressL4": .unknownString, //OrgaddressL4
        "Orgtel": .unknownString, //Orgtel
        "Orgmobile": .unknownString, //Orgmobile
        "Orgfax": .unknownString, //Orgfax
        "OrgEmail": .string(expectedLength: nil, startsWith: nil, contains: "@"), //OrgEmail
        "OrgEntryEmail": .string(expectedLength: nil, startsWith: nil, contains: "@"),
        "Orgemailentries": .string(expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailentries
        "Orgemailaccomodation": .string(expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailaccomodation
        "Orgemailtransportation": .string(expectedLength: nil, startsWith: nil, contains: "@"), //Orgemailtransportation
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
        "Selcat": .string(expectedLength: nil, startsWith: "-", contains: nil), //Selcat
        "Seldis": .string(expectedLength: nil, startsWith: "-", contains: nil), //Seldis
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
        "Skip_wcsl": .unknownString,
        "Published": .unknownString,
        "Passwd": .unknownString,
        "Homol": .unknownString,
        "Receiveddate": .unknownString,
        "Racecodex": .unknownString,
        "Td2code": .unknownString,
        "Level": .unknownString,
        "Hcet1": .unknownString,
        "Hcet3": .unknownString,
        "Noepr": .unknownString,
        "Timinglogo": .unknownString,
        "Catcode": .unknownString,
        "Td1id": .unknownString,
        "Validforfispoints": .unknownString,
        "Live": .unknownString,
        "Td2id": .unknownString,
        "Penscafixed": .unknownString,
        "Gender_2021": .unknownString,
        "Catcode4": .unknownString,
        "Hill": .unknownString,
        "Special_cup_points": .unknownString,
        "Livestatus1": .unknownString,
        "Mssql7id": .unknownString,
        "Webcomment": .unknownString,
        "Eventid": .unknownString,
        "Pursuit": .unknownString,
        "Appliedpenalty": .unknownString,
        "Livestatus2": .unknownString,
        "Disciplineid": .unknownString,
        "Place": .unknownString,
        "Appliedscala": .unknownString,
        "Td1nation": .unknownString,
        "Provraceid": .unknownString,
        "Gallery": .unknownString,
        "Liveinfo2": .unknownString,
        "Td2nation": .unknownString,
        "Pdf": .unknownString,
        "Racedate": .unknownString,
        "Qualif": .unknownString,
        "Indi": .unknownString,
        "Td2name": .unknownString,
        "Columncount": .unknownString,
        "Hcet2": .unknownString,
        "Liveinfo3": .unknownString,
        "Bottomlogo": .unknownString,
        "validdate": .unknownString,
        "Raceid": .unknownString,
        "Nationraceid": .unknownString,
        "Tabcount": .unknownString,
        "Livestatus3": .unknownString,
        "Team": .unknownString,
        "Catcode3": .unknownString,
        "Displaystatus": .unknownString,
        "Version": .unknownString,
        "Validdate": .unknownString,
        "Topbanner": .unknownString,
        "Timingreport": .unknownString,
        "Tolist": .unknownString,
        "Relay": .unknownString,
        "Discforlistcode": .unknownString,
        "Hloc2": .unknownString,
        "Lastupdate": .unknownString,
        "Catcode2": .unknownString,
        "Livestatus": .unknownString,
        "Results": .unknownString,
        "Hloc1": .unknownString,
        "Gender": .unknownString,
        "Msql7evid": .unknownString,
        "Bottombanner": .unknownString,
        "Liveinfo1": .unknownString,
        "Masse": .unknownString,
        "Liveinfo": .unknownString,
        "Disciplinecode": .unknownString,
        "Td1code": .unknownString,
        "Nationcode": .unknownString,
        "Procstatuscode": .unknownString,
        "Finale": .unknownString,
        "Hloc3": .unknownString,
        "TDdoc": .unknownString,
        "Style": .unknownString,
        "Td1name": .unknownString,
        "Fisinterncomment": .unknownString,
        "Distance": .unknownString,
        "Usedfislist": .unknownString,
        "Calstatuscode": .unknownString,
        "Toplogo": .unknownString,
        "Calculatedpenalty": .unknownString,
        "Seasoncode": .unknownString,
        "Starteventdate": .unknownString,
        "Description": .unknownString
    ]
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
