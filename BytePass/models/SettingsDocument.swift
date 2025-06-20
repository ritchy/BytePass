//
//  SettingsDocument.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/19/25.
//

import Foundation

/***
 
 Processes and manages the following JSON example
  {
   "key_base64": "---",
      "auth_client": {
        "last_updated": "2025-05-02 21:43:17.338996",
        "data": "xxxxx",
        "type": "Bearer",
        "expiry": "2025-05-03 02:42:56.338556Z",
        "refresh_token": "---"
      },
      "client_access_id": "1739137259149"
    }
 **/
struct SettingsDocument: Codable {
    var keyBase64: String
    //let lastUpdated: String
    var clientId: String
    var authClient: AuthClientDocument
    enum CodingKeys: String, CodingKey {
        case keyBase64 = "key_base64"
        //case lastUpdated = "last_updated"
        case clientId = "client_access_id"
        case authClient = "auth_client"
    }
}

struct AuthClientDocument: Codable {
    var lastUpdated: String
    var data: String
    var type: String
    var expiry: String
    var refreshToken: String

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case data
        case type
        case expiry
        case refreshToken = "refresh_token"
    }
}

