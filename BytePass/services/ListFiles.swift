//
//  ListFiles.swift
//  BytePass
//
//  Created by Robert Ritchy on 5/16/25.
//

import Foundation
import Logging

public struct ListFiles: Sendable {
    let params: Params
    let log = Logger(label: "com.jarbo.bytepass.ListFiles")

    func buildRequest() -> URLRequest {
        var request: URLRequest  //= {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/drive/v3/files"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "fields", value: FilesList.apiFields)
        ]
        if params.corpora != nil {
            queryItems.append(
                URLQueryItem(name: "corpora", value: params.corpora?.rawValue)
            )
        }
        if params.driveId != nil {
            queryItems.append(
                URLQueryItem(name: "driveId", value: params.driveId)
            )
        }
        if let includeItemsFromAllDrives = params.includeItemsFromAllDrives {
            let value = includeItemsFromAllDrives ? "true" : "false"
            queryItems.append(
                URLQueryItem(name: "includeItemsFromAllDrives", value: value)
            )
        }
        if !params.orderBy.isEmpty {
            let value = params.orderBy.map(\.string).joined(separator: ",")
            queryItems.append(URLQueryItem(name: "orderBy", value: value))
        }
        if let pageSize = params.pageSize {
            queryItems.append(
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            )
        }
        if let pageToken = params.pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        if let query = params.query {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if !params.spaces.isEmpty {
            let value = params.spaces.map(\.rawValue).joined(separator: ",")
            queryItems.append(URLQueryItem(name: "spaces", value: value))
        }
        if let supportsAllDrives = params.supportsAllDrives {
            let value = supportsAllDrives ? "true" : "false"
            queryItems.append(
                URLQueryItem(name: "supportsAllDrives", value: value)
            )
        }
        components.queryItems = queryItems

        request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        return request
    }
    
    //return The type of the value to decode.
    func getDecodeType() {
    }
    
    func decodeResponse(data: Data){
        let decoder = JSONDecoder()
        do {
            let filesList = try decoder.decode(FilesList.self, from: data)
            log.debug ("incomplete? \(filesList.incompleteSearch)")
            log.debug ("files returned \(filesList.files.count)")
        } catch {
            log.error("ListFiles failure", metadata: [
              "error": "\(error)",
              "localizedDescription": "\(error.localizedDescription)"
            ])
          }
    }
}

public struct FilesList: Sendable, Equatable, Codable {
    public init(
        nextPageToken: String?,
        incompleteSearch: Bool,
        files: [File]
    ) {
        self.nextPageToken = nextPageToken
        self.incompleteSearch = incompleteSearch
        self.files = files
    }

    public var nextPageToken: String?
    public var incompleteSearch: Bool
    public var files: [File]
    static var apiFields: String = [
        "nextPageToken",
        "incompleteSearch",
        "files(" + File.apiFields + ")",
    ].joined(separator: ",")
}

/*
 createdTime = "2024-07-06T17:44:22.410Z";
 id = "1nqGBvieZayqKktiycP-FSKECNdd-JPDc";
 mimeType = "text/html";
 modifiedTime = "2024-07-05T17:39:51.000Z";
 name = "etrade_march.html";
 */
public struct File: Sendable, Equatable, Identifiable, Codable {
    public init(
        createdTime: String,
        id: String,
        mimeType: String,
        modifiedTime: String,
        name: String
    ) {
        self.id = id
        self.mimeType = mimeType
        self.name = name
        self.createdTime = createdTime
        self.modifiedTime = modifiedTime
    }

    public var id: String
    public var mimeType: String
    public var name: String
    public var createdTime: String
    public var modifiedTime: String
    static var apiFields: String = [
        "id",
        "mimeType",
        "name",
        "createdTime",
        "modifiedTime",
    ].joined(separator: ",")
}

public struct Params: Sendable, Equatable {
    public enum Corpora: String, Sendable, Equatable {
        case user, domain, drive, allDrives
    }

    public enum Space: String, Sendable, Equatable {
        case drive, appDataFolder
    }

    public struct OrderBy: Sendable, Equatable, Hashable {
        public static let createdTime = OrderBy("createdTime")
        public static let folder = OrderBy("folder")
        public static let modifiedByMeTime = OrderBy("modifiedByMeTime")
        public static let modifiedTime = OrderBy("modifiedTime")
        public static let name = OrderBy("name")
        public static let name_natural = OrderBy("name_natural")
        public static let quotaBytesUsed = OrderBy("quotaBytesUsed")
        public static let recency = OrderBy("recency")
        public static let sharedWithMeTime = OrderBy("sharedWithMeTime")
        public static let starred = OrderBy("starred")
        public static let viewedByMeTime = OrderBy("viewedByMeTime")

        public init(_ field: String, descending: Bool = false) {
            self.field = field
            self.descending = descending
        }

        public var field: String
        public var descending: Bool

        public func desc() -> OrderBy {
            OrderBy(field, descending: true)
        }

        var string: String { "\(field)\(descending ? " desc" : "")" }
    }

    public init(
        corpora: Corpora? = nil,
        driveId: String? = nil,
        includeItemsFromAllDrives: Bool? = nil,
        orderBy: Set<OrderBy> = [],
        pageSize: Int? = nil,
        pageToken: String? = nil,
        query: String? = nil,
        spaces: Set<Space> = [],
        supportsAllDrives: Bool? = nil
    ) {
        self.corpora = corpora
        self.driveId = driveId
        self.includeItemsFromAllDrives = includeItemsFromAllDrives
        self.orderBy = orderBy
        self.pageSize = pageSize
        self.pageToken = pageToken
        self.query = query
        self.spaces = spaces
        self.supportsAllDrives = supportsAllDrives
    }

    public var corpora: Corpora?
    public var driveId: String?
    public var includeItemsFromAllDrives: Bool?
    public var orderBy: Set<OrderBy>
    public var pageSize: Int?
    public var pageToken: String?
    public var query: String?
    public var spaces: Set<Space>
    public var supportsAllDrives: Bool?
}
