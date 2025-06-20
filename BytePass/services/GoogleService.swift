//
//  GoogleService.swift
//  BytePass
//
//  Created by Robert Ritchy on 5/14/25.
//

import Foundation
import GoogleDriveClient
import GoogleSignIn
import Logging

class GoogleService: ObservableObject {
    let log = Logger(label: "com.jarbo.bytepass.GoogleService")
    var dataManager = DataManager()

    private let baseUrlString = "https://people.googleapis.com/v1/people/me"
    private let fileListQuery = URLQueryItem(name: "trash", value: "false")

    //var isSignedIn = false
    var filesList: FilesList?
    var fileContent: String?
    enum Error: Swift.Error {
        case couldNotCreateURLSession(Swift.Error?)
        case couldNotCreateURLRequest
        case userHasNoBirthday
        case couldNotFetchBirthday(underlying: Swift.Error)
    }
    enum GoogleServiceError: Swift.Error {
        case unableToRetrieveFile
        case missingFiles
    }

    public static let liveValue = Client.live(
        config: Config(
            clientID:
                "324613767651-n7v5dn0upkc91f4movirt2n67sqbd6iq.apps.googleusercontent.com",
            //"545101176261-21ebgkhd40k58tsu59lg5u99mp7nludn.apps.googleusercontent.com",
            authScope: "https://www.googleapis.com/auth/drive.appdata",
            //authScope: "https://www.googleapis.com/auth/drive",
            redirectURI:
                "com.googleusercontent.apps.324613767651-n7v5dn0upkc91f4movirt2n67sqbd6iq://"
                //"com.googleusercontent.apps.545101176261-21ebgkhd40k58tsu59lg5u99mp7nludn://"
        )
    )

    var googleDriveClient: GoogleDriveClient.Client

    public init() {
        self.googleDriveClient = GoogleService.liveValue
    }

    func isSignedIn() async -> Bool {
        return await googleDriveClient.auth.isSignedIn()
    }

    func handleRedirect(url: URL) async throws {
        try await _ = googleDriveClient.auth.handleRedirect(url)
    }

    func signIn() async throws {
        if await googleDriveClient.auth.isSignedIn() {
            return
        } else {
            await googleDriveClient.auth.signIn()
        }
    }

    func signOut() async throws {
        await googleDriveClient.auth.signOut()
    }

    func getFileInfo() async throws {
        do {
            let filesList: GoogleDriveClient.FilesList =
                try await googleDriveClient.listFiles {
                    $0.query = "trashed=false"
                    //$0.spaces = [.drive]
                    $0.spaces = [.appDataFolder]
                }
            //log.info("got back files list \(filesList)")
            for file in filesList.files {
                log.info("file \(file.name)")
                if file.name == "accounts.json" {
                    log.info("FOUND ACCOUNTS FILE IN DRIVE")
                    try await getFileData(fileId: file.id)
                }
            }
        } catch {
            log.error(
                "ListFiles failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
    }

    func createTestFile() async throws {
        do {
            log.info("let's create a test file in the app folder ..")
            let dateText = Date().formatted(date: .complete, time: .complete)
            _ = try await googleDriveClient.createFile(
                name: "test.txt",
                spaces: "appDataFolder",
                mimeType: "text/plain",
                parents: ["appDataFolder"],
                data: "Hello, World!\nCreated at \(dateText)".data(
                    using: .utf8
                )!
            )
        } catch {
            log.error(
                "createTestFile() failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
    }

    func getAppFolderId() async throws -> String? {
        log.info("listing files in the app folder ...")
        let signedIn = await googleDriveClient.auth.isSignedIn()
        log.info("getAppFolderId() - Logged in? -> \(signedIn)")
        let filesList: GoogleDriveClient.FilesList =
            try await googleDriveClient.listFiles {
                $0.query = "trashed=false"  //,mimeType=application/vnd.google-apps.folder"
                $0.spaces = [.appDataFolder]
                //$0.spaces = [.drive]
                $0.orderBy = [.folder]
            }
        log.info("got app folder list")
        for file in filesList.files {
            log.info("app folder? \(file.name) \(file.mimeType)")
            if file.name == "ByteStream" {
                log.info("found app folder")
                return file.id
            }
        }
        log.error("unable to locate the app folder in Drive")
        return nil
    }

    func getFileId(fileName: String) async throws -> String? {
        let signedIn = await googleDriveClient.auth.isSignedIn()
        log.info("getAppFolderId() - Logged in? -> \(signedIn)")
        let filesList: GoogleDriveClient.FilesList =
            try await googleDriveClient.listFiles {
                $0.query = "trashed=false"
                $0.spaces = [.appDataFolder]
                //$0.spaces = [.drive]
                //$0.orderBy = [.folder]
            }
        //log.info("got back files list \(filesList)")
        for file in filesList.files {
            //log.info("access file? \(file.name) \(file.mimeType)")
            if file.name == fileName {
                log.info("found \(fileName) in drive")
                return file.id
            }
        }
        return nil
    }

    func retrieveAccessFile() async -> (AccessDocument?, Data?) {
        log.info("downloading access file from Drive ...")
        do {
            let signedIn = await googleDriveClient.auth.isSignedIn()
            log.info("retrieveAccessFile() - Logged in? -> \(signedIn)")
            let fileId = try await getFileId(fileName: "access.json")
            if let fileId = fileId {
                let data = try await googleDriveClient.getFileData(
                    fileId: fileId
                )
                log.info(
                    "retrieved access document from Drive: \(String(describing: data))"
                )
                let decoder = JSONDecoder()
                let accessDocument = try decoder.decode(
                    AccessDocument.self,
                    from: data
                )
                return (accessDocument, data)
            } else {
                //access file was not found in Drive, create an emtpy one
                log.info(
                    "access file was not found in Drive, creating an emtpy one .. "
                )
                let (accessDocument, data) =
                    await dataManager.createNewAccessDocument()
                if accessDocument != nil && data != nil {
                    _ = await saveFileInDrive(
                        fileName: "access.json",
                        mimeType: "application/json",
                        data: data!
                    )
                    return (accessDocument, data)
                }
            }
        } catch {
            log.error(
                "retrieveAccessFile() failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
        log.info(
            "Returning nothing because no access file was found in Drive and we were unable to create one"
        )
        return (nil, nil)
    }

    func saveFileInDrive(fileName: String, mimeType: String, data: Data) async
        -> Bool
    {
        log.info("saving \(fileName) in Drive, first finding existing ...")
        do {
            let signedIn = await googleDriveClient.auth.isSignedIn()
            log.info("saveFileInDrive() - Logged in? -> \(signedIn)")
            let filesList: GoogleDriveClient.FilesList =
                try await googleDriveClient.listFiles {
                    $0.query = "trashed=false"
                    $0.spaces = [.appDataFolder]
                }
            //log.info("got back files list \(filesList)")
            for file in filesList.files {
                //log.info("access file? \(file.name) \(file.mimeType)")
                if file.name == fileName {
                    log.info("found \(fileName) in drive, updating ...")
                    _ = try await googleDriveClient.updateFileData(
                        fileId: file.id,
                        data: data,
                        mimeType: mimeType
                    )
                    return true
                }
            }
            //file doesn't exist,so create new one
            log.info(
                "\(fileName) doesn't exist, so creating rather than updating ..."
            )
            try await _ = googleDriveClient.createFile(
                name: fileName,
                spaces: "appDataFolder",
                mimeType: mimeType,
                parents: ["appDataFolder"],
                data: data
            )
            return true

        } catch {
            log.error(
                "saveFileInDrive failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
        return false
    }

    func retrieveAccountsFile() async throws -> (AccountsDocument?, Data?) {
        log.info("retrieving accounts document from Drive ....")
        do {
            let signedIn = await googleDriveClient.auth.isSignedIn()
            log.info("retrieveAccountsFile() - Logged in? -> \(signedIn)")
            let fileId = try await getFileId(fileName: "accounts.json")
            if let fileId = fileId {
                let data = try await googleDriveClient.getFileData(
                    fileId: fileId
                )
                log.info(
                    "retrieved accounts document from Drive: \(String(describing: data))"
                )
                let decoder = JSONDecoder()
                let accountsDocument = try decoder.decode(
                    AccountsDocument.self,
                    from: data
                )
                return (accountsDocument, data)
            } else {
                //access file was not found in Drive, create an emtpy one
                log.info(
                    "accounts file was not found in Drive, creating one from local copy ... "
                )
                let accountsDocument = dataManager.accountsDocument
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(accountsDocument)
                let success = await saveFileInDrive(
                    fileName: "accounts.json",
                    mimeType: "application/json",
                    data: data
                )
                if success {
                    return (accountsDocument, data)
                }
            }
        } catch {
            log.error(
                "retrieveAccountsFile() failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
        log.info(
            "Returning nothing because no accounts file was found in Drive and we were unable to create one"
        )
        return (nil, nil)
    }

    func getFileData(fileId: String) async throws {
        log.info("getting file data for \(fileId)")
        do {
            let params = GetFileData.Params(fileId: fileId)
            let data = try await googleDriveClient.getFileData(params)
            log.info("got data back, now saving ...")
            await dataManager.saveFile(name: "a.json", data: data)
            if let string = String(data: data, encoding: .utf8) {
                fileContent = string
            } else {
                fileContent = data.base64EncodedString()
            }
            //log.info ("Got file with content: \(String(describing: fileContent))")
        } catch {
            log.error(
                "GetFileData failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
    }

    func updateDriveAccountsDocument() async -> Bool {
        log.info("Updating accounts document on Drive ...")
        do {
            let accountsDocument = dataManager.accountsDocument
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(accountsDocument)
            return await saveFileInDrive(
                fileName: "accounts.json",
                mimeType: "application/json",
                data: data
            )
        } catch {
            log.error(
                "Update Accounts Document failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
        return false
    }

    func syncAccountsDocument() async -> Bool {
        log.info("Syncing accounts document ...")
        do {
            //download accounts file and reconcile
            //get access file from Drive to help manage it
            let (incomingAccountsDocument, _) =
                try await retrieveAccountsFile()
            //var accountsDocument = AccountsDocument(passwordEntry: [])
            //log.info(
            //    "accounts doc from Drive: \(String(describing: incomingAccountsDocument))"
            //)
            //log.info("saved accounts file to local folder, now reconcile ...")
            //save accounts file from drive to local folder
            log.info(
                "incoming accounts with \(String(describing: incomingAccountsDocument?.accounts.count)) entries"
            )
            log.info("reconciling local accounts with incoming from drive ...")
            let changesMadeToIncoming = await dataManager.reconcileAccounts(
                incomingAccountsDocument: incomingAccountsDocument!
            )
            return changesMadeToIncoming
        } catch {
            log.error(
                "Sync Accounts Document failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
        return false  //AccountsDocument(passwordEntry: [])
    }

    func syncAccessDocument() async -> AccessDocument? {
        //download accounts file and reconcile
        //get access file from Drive to help manage it
        let (accessDocument, data) = await retrieveAccessFile()
        //print ("access doc from Drive: \(String(describing: accessDocument))")
        if accessDocument == nil {
            log.warning(
                "unable to retrieve access document from Drive, so can't complete sync"
            )
            return nil
        } else {
            //save from drive
            await dataManager.saveFile(name: "access.json", data: data!)
        }
        return accessDocument
    }

    func requestAccess() async {

        var settingsDocument = await dataManager.loadSettingsDocument()
        let clientId = settingsDocument?.clientId ?? "----"
        //handle access document
        var accessDocument = await syncAccessDocument()
        //first make sure we don't have any existing entry
        for client in accessDocument?.clients ?? [] {
            if client.clientId == clientId {
                log.warning("we already have a request for this client")
                return
            }
        }

        // generate pub/priv keys if missing and request access
        if accessDocument != nil {
            //let currentHost = Platform.operatingSystem
            let currentHostName = ProcessInfo.processInfo.hostName
            log.info("CURRENT HOST: \(currentHostName)")
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [
                .withFullDate, .withTime, .withDashSeparatorInDate,
                .withColonSeparatorInTime, .withFractionalSeconds,
            ]
            let timestamp = dateFormatter.string(from: Date())
            let newClientId =
                "\(currentHostName)-\(Date().timeIntervalSince1970)"
            let clientDocument = ClientDocument(
                lastUpdated: timestamp,
                clientId: newClientId,
                clientName: currentHostName,
                publicKey: "-----",
                encryptedAccessKey: "",
                accessStatus: "requested"
            )
            accessDocument!.lastUpdated = timestamp
            accessDocument!.addClientRequest(clientDocument: clientDocument)
            log.info(" new access file: \(String (describing: accessDocument))")
            log.info("saving new access file locally ...")
            let (_, _) = await dataManager.saveAccessDocument(
                accessDocument: accessDocument!
            )
            log.info("saving new access file in drive...")
            //await saveAccessFileInDrive(accessDocument: accessDocument!)
            settingsDocument?.clientId = newClientId

        } else {
            log.error("Unable to load access document")
        }

    }

    /*
     Syncs with GoogleDrive:
        1. check for key in local settings file, if key exist:
           a. check files exist in drive: access and accounts
           b. if they don't,create empty access file and encrypted accounts file
           c. if access and accounts do exist, then download both:
                1. reconcile with local accounts
                2. manage access file for any new requests
        2. if local key does NOT exist in local settings, download access and look for client_access_id from settings
           a. if client_access_id is found in access file, then check status: rejected/accepted/
           b. if client_access_id is NOT found, generate one, request access and add client_access_id to local settings
     */
    func handleSync() async {
        do {
            try await signIn()
            //todo: load this through environment
            //check for key in local settings file
            let settingsDocument = await dataManager.loadSettingsDocument()
            let keyBase64 = settingsDocument?.keyBase64
            //print ("key: \(String(describing: keyBase64))")

            //for testing ->
            //await requestAccess()
            if keyBase64 == nil {
                log.info("we don't have access to Drive file, requesting ...")
                await requestAccess()
            } else {
                let needToUpdateDriveDocment = await syncAccountsDocument()
                if needToUpdateDriveDocment {
                    log.info(
                        "updates made from local changes, need to push to Drive ..."
                    )
                    await _ = updateDriveAccountsDocument()
                } else {
                    log.info("no local updates made, no need to push to Drive ...")
                }
                //await handleAccessRequests()
            }
        } catch {
            log.error(
                "signin() failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription": "\(error.localizedDescription)",
                ]
            )
        }
    }

    func listFiles() async throws {
        var token: String?
        GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded {
            user,
            error in
            guard error == nil else { return }
            guard let user = user else { return }

            // Get the access token to attach it to a REST or gRPC request.
            let accessToken = String(user.accessToken.tokenString)
            token = accessToken
            // Or, get an object that conforms to GTMFetcherAuthorizationProtocol for
            // use with GTMAppAuth and the Google APIs client library.
            //let authorizer = user.fetcherAuthorizer()
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/drive/v3/files"
        //let url = URL(string: "api.example.com/user")!
        //print ("same token?")
        //print (GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString ?? "no token value")
        let url = components.url!
        var request = URLRequest(url: url)
        log.debug("request url: \(String(describing: request.url))")
        let listFiles = ListFiles(params: Params(query: "trashed=false"))
        request = listFiles.buildRequest()
        log.info("listFiles url: \(String(describing: request.url))")
        log.debug("got auth API token \(String(describing: token))")
        let authToken = GIDSignIn.sharedInstance.currentUser?.accessToken
            .tokenString
        if authToken != nil {
            request.setValue(
                "Bearer \(authToken ?? "")",
                forHTTPHeaderField: "Authorization"
            )
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard let statusCode, (200..<300).contains(statusCode) else {
            print("got error in response \(String(describing: response))")
            return
        }
        //switch response.statusCode {
        //    case 400 ..< 500: throw APIError.client
        //    case 500 ..< 600: throw APIError.server
        //    default: break
        //}
        //print ("return data...")
        let JSONResponse = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        )
        if let JSONResponse = JSONResponse as? [String: Any] {
            //print(JSONResponse)
            listFiles.decodeResponse(data: data)
            //let decoder = JSONDecoder()
            //let filesList = try decoder.decode(FilesList.self, from: data)
            //print (filesList.files.count)
        }
    }

    private lazy var components: URLComponents? = {
        let personFieldsQuery = URLQueryItem(
            name: "personFields",
            value: "birthdays"
        )
        var comps = URLComponents(string: baseUrlString)
        comps?.queryItems = [personFieldsQuery]
        return comps
    }()

    private lazy var request: URLRequest? = {
        guard let components = components, let url = components.url else {
            return nil
        }
        return URLRequest(url: url)
    }()

    private lazy var session: URLSession? = {
        guard
            let accessToken = GIDSignIn
                .sharedInstance
                .currentUser?
                .accessToken
                .tokenString
        else { return nil }
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        return URLSession(configuration: configuration)
    }()

    private func sessionWithFreshToken(
        completion: @escaping (Result<URLSession, Error>) -> Void
    ) {
        GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded {
            user,
            error in
            guard let token = user?.accessToken.tokenString else {
                completion(.failure(.couldNotCreateURLSession(error)))
                return
            }
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = [
                "Authorization": "Bearer \(token)"
            ]
            let session = URLSession(configuration: configuration)
            completion(.success(session))
        }
    }

}
