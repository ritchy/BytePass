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
   "key_base64": "gc0VH2sWvlHOXCXhxqvzuFo2XuwPaD56b9LgBIzzRbE=",
      "auth_client": {
        "last_updated": "2025-05-02 21:43:17.338996",
        "data": "ya29.a0AZYkNZg6GzhMUTz5QFVaUsidazbzqH4WXJX7A6NH7HDqCQmpQpLN53K1_CaVZ2G0hQxx_d4iPLbvBPaB4d6TqiY5ikmJV0R-4r2ttibrNrcTwjRTueu129E6n3hcvAla33dGv_LpUwy9DLEYDIf-3Yb033_NTRCiE5vl_z6_XwaCgYKAfQSARESFQHGX2Mi3gpjd_QasBiis9oxrDDi2Q0177",
        "type": "Bearer",
        "expiry": "2025-05-03 02:42:56.338556Z",
        "refresh_token": "1//0fh1Xjm4oR44fCgYIARAAGA8SNwF-L9Irfm1Ar1ZM9RsuZfw1dfhiCtiVzP7N_mGvlsL8YGmDJFLcM5et2Om2E5TIxlvT7SfmLW4"
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

