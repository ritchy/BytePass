//
//  AccountsDocument.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/19/25.
//

import Foundation

struct AccountsDocument: Codable {
    var lastUpdated: String = String(NSDate().timeIntervalSince1970 * 1000)
    var accounts: [Account]
}

struct Account: Codable, Identifiable, Equatable {
    var name: String
    var lastUpdated: String
    var status: String
    var id: Int
    var username: String
    var password: String
    var accountNumber: String
    var url: String
    var email: String
    var hint: String
    var notes: String
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case lastUpdated = "last_updated"
        case status
        case id
        case username
        case password
        case accountNumber = "account_number"
        case url
        case email
        case hint
        case notes
        case tags
    }

    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name && lhs.status == rhs.status && lhs.id == rhs.id
            && lhs.username == rhs.username && lhs.password == rhs.password
            && lhs.accountNumber == rhs.accountNumber && lhs.url == rhs.url
            && lhs.email == rhs.email && lhs.hint == rhs.hint
            && lhs.notes == rhs.notes && lhs.tags == rhs.tags
    }

    enum EntryStatus: String {
        case active
        case deleted
    }

    static func generateNewId() -> Int {
        let currentTimeInMillis = Int64(NSDate().timeIntervalSince1970 * 1000)
        return Int(currentTimeInMillis)
    }

    static func generateNewDateString() -> String {
        let currentTimeInMillis = Int64(NSDate().timeIntervalSince1970 * 1000)
        return String(currentTimeInMillis)
    }

    static func generateNewFormattedDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDate = Date()
        let formattedDateString =
            dateFormatter.string(
                from: currentDate
            )
        return formattedDateString
    }

    func isValid() -> Bool {
        return !name.isEmpty && name != "" && name != "New Account"
    }

    mutating func addTag(_ tagName: String) {
        if !tags.contains(tagName) {
            tags.append(tagName)
        }
    }

    static var emptyAccount: Account {
        Account(
            name: "",
            lastUpdated: generateNewDateString(),
            status: "active",
            id: generateNewId(),
            username: "",
            password: "",
            accountNumber: "",
            url: "",
            email: "",
            hint: "",
            notes: "",
            tags: []
        )
    }
}

