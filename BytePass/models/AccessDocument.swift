//
//  Untitled.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/19/25.
//
import Foundation

struct AccessDocument: Codable {
    var lastUpdated: String
    var clients: [ClientDocument]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case clients
    }

    mutating func addClientRequest(clientDocument: ClientDocument) {
        self.clients.append(clientDocument)
    }
}

enum AccessStatus: String {
    case granted
    case requested
    case denied
}

struct ClientDocument: Codable {
    let lastUpdated: String
    let clientId: String
    let clientName: String
    let publicKey: String
    let encryptedAccessKey: String
    let accessStatus: String

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case clientId = "client_id"
        case clientName = "client_name"
        case publicKey = "public_key"
        case encryptedAccessKey = "encrypted_access_key"
        case accessStatus = "access_status"
    }

}
