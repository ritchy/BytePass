import CryptoKit
import Foundation
import Logging

class DataManager: ObservableObject {
    @Published var entries: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isDataLoaded = false
    @Published var searchResults: [Account] = []

    var accountsDocument = AccountsDocument(accounts: [])
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    let log = Logger(label: "com.jarbo.bytepass.DataManager")

    init() {
        print("NEW DATA MANAGER")
        documentsDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        Task {
            do {
                if try await loadAccountsDocument() {
                    log.info("loaded local accounts document")
                }
            } catch {
                log.error(
                    "problem loading local accounts document: \(error.localizedDescription)"
                )
            }
        }
    }

    func saveFile(name: String, data: Data) async {
        do {
            // Create a unique directory for this data if it doesn't exist
            let dataDirectory = documentsDirectory.appendingPathComponent(
                "BytePassData",
                isDirectory: true
            )

            if !fileManager.fileExists(atPath: dataDirectory.path) {
                try fileManager.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
            }

            // Save the original copy
            let originalFilePath = dataDirectory.appendingPathComponent(name)
            do {
                try data.write(to: originalFilePath, options: .atomic)
                log.info("Saved: \(originalFilePath.path)")
            } catch {
                log.error("Error saving file: \(error.localizedDescription)")
                throw error
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func loadJSON(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Create a unique directory for this data if it doesn't exist
            let dataDirectory = documentsDirectory.appendingPathComponent(
                "BytePassData",
                isDirectory: true
            )

            if !fileManager.fileExists(atPath: dataDirectory.path) {
                try fileManager.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
            }

            // Save the original copy
            let originalFilePath = dataDirectory.appendingPathComponent(
                "original_data.json"
            )
            do {
                try data.write(to: originalFilePath, options: .atomic)
                print("Original data saved to: \(originalFilePath.path)")
            } catch {
                print(
                    "Error saving original data: \(error.localizedDescription)"
                )
                throw error
            }

            // Save the encrypted copy
            let key = await loadKey()
            let encryptedData = encryptData(data, key: key)
            let encryptedFilePath = dataDirectory.appendingPathComponent(
                "encrypted_data.json"
            )

            // let's test
            let decryptedData = decryptData(encryptedData, key: key)
            let decryptedString = String(data: decryptedData, encoding: .utf8)
            print("decrypted string\n\(decryptedString!)")

            // try unencrypting the official file
            print("now let's try the official file ...")
            let eFilePath = documentsDirectory.appendingPathComponent(
                "BytePassData"
            )
            .appendingPathComponent("bpass-encrypted.json")

            // Decrypt the file
            let dData = decryptFile(at: eFilePath, key: key)

            // Use the decrypted data (e.g., convert to string if it's text)
            if let decryptedString = String(data: dData, encoding: .utf8) {
                print("Decrypted content: \(decryptedString)")
            }
            print("done trying the official file ...")

            do {
                try encryptedData.write(to: encryptedFilePath, options: .atomic)
                print("Encrypted data saved to: \(encryptedFilePath.path)")
            } catch {
                print(
                    "Error saving encrypted data: \(error.localizedDescription)"
                )
                throw error
            }

            // Parse the JSON
            let decoder = JSONDecoder()
            //let entries: [Account]
            //var accountsDocument: AccountsDocument
            do {
                accountsDocument = try decoder.decode(
                    AccountsDocument.self,
                    from: data
                )
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
                throw error
            }

            await MainActor.run {
                self.entries = accountsDocument.accounts
                self.isLoading = false
                self.isDataLoaded = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func decryptAccountsFile(fileName: String) async throws -> AccountsDocument
    {
        //await loadJSON(from: "http://bytestream.io/accounts.json")
        log.info("decrypting file: \(fileName) ...")
        let key = await loadKey()
        print(key)
        let eFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData"
        )
        .appendingPathComponent(fileName)
        let nFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData"
        )
        .appendingPathComponent("decrypt.txt")

        // Decrypt the file
        let data = decryptFile(at: eFilePath, key: key)
        try data.write(to: nFilePath, options: .atomic)
        // Use the decrypted data (e.g., convert to string if it's text)
        //print ("is this null???")
        //let d = Data(base64Encoded: data)
        //if d == nil {
        //    print ("null data??!!!")
        //}
        //print ("----> \(String (describing: d))")
        //let s = String (data: d!, encoding: .utf8)
        //if s == nil {
        //    print ("null string")
        //} else {
        //    print (s!)
        //}
        //print (String (data: d!, encoding: .utf8) ?? "no string from decrypt??")

        //Data(base64Encoded: data)
        if let decryptedString = String(data: data, encoding: .utf8) {
            print(
                "Decrypted content: \(String(Array(decryptedString)[0...40]))"
            )
        } else {
            print("not sure what happened??")
        }

        let incomingFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData"
        )
        .appendingPathComponent("incoming.json")

        if fileManager.fileExists(atPath: incomingFilePath.path) {
            do {
                let data = try Data(contentsOf: incomingFilePath)
                let decoder = JSONDecoder()
                log.info("now decode incoming JSON ..")
                let entries: [Account]
                entries = try decoder.decode([Account].self, from: data)
                return AccountsDocument(accounts: entries)
                //return try decoder.decode(AccountsDocument.self, from: data)
            } catch {
                log.error("problem loading incoming file")
            }
        }
        return AccountsDocument(accounts: [])
    }

    func loadAccountsDocument() async throws -> Bool {
        let accountsFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )
        .appendingPathComponent("accounts.json")

        // Check if the file exists
        if fileManager.fileExists(atPath: accountsFilePath.path) {
            log.info("found local accounts file, loading ...")
            do {
                let data = try Data(contentsOf: accountsFilePath)
                // Parse the JSON
                let decoder = JSONDecoder()
                //let entries: [Account]
                //let accountsDocument: AccountsDocument
                do {
                    accountsDocument = try decoder.decode(
                        AccountsDocument.self,
                        from: data
                    )
                    log.info(
                        "loaded \(accountsDocument.accounts.count) accounts"
                    )
                } catch {
                    print(
                        "Error decoding accounts JSON: \(error.localizedDescription) file path: \(accountsFilePath)"
                    )
                    throw error
                }
                //accountsDocument.accounts = entries
                await MainActor.run {
                    self.entries = accountsDocument.accounts
                    self.isLoading = false
                    self.isDataLoaded = true
                }
                return true
            } catch {
                print(
                    "Error loading accounts.json: \(error.localizedDescription)"
                )
            }
        } else {
            //no local accounts file, then create
            log.warning(
                "there was no local accounts file, so creating new one ..."
            )
            var (_, _) = await createNewAccountsDocument()
            //accountsDocument?.accounts = entries
            await MainActor.run {
                self.entries = []
                self.isLoading = false
                self.isDataLoaded = true
            }
            return true
        }
        return false
    }

    func getEntryById(_ id: Int, providedEntries: [Account]? = nil)
        -> Account?
    {
        let toSearch = providedEntries ?? entries
        return toSearch.first { $0.id == id }
    }

    func replaceEntry(_ entry: Account) async {

        let index = entries.firstIndex(where: { $0.id == entry.id }) ?? -1
        if index > 0 {
            await MainActor.run {
                entries[index] = entry
            }
            log.info ("replaced \(entry.id) - \(entry.name) - \(entry.notes)")
            //entries.sorted { $0.name < $1.name }
        } else {
            log.warning("Unable to find entry to replace: \(entry.id) - \(entry.name)")
        }

        //await MainActor.run {
        //    entries.removeAll { $0.id == entry.id }
        //    entries.append(entry)
        //}
    }

    func addEntry(_ entry: Account) async {
        await MainActor.run {
            entries.append(entry)
        }
    }

    func reconcileAccounts(incomingAccountsDocument: AccountsDocument) async
        -> Bool
    {
        log.info("reconcileAccounts with latest version")
        log.info(
            "we currently have \(entries.count) accounts loaded"
        )
        var changesMadeToIncomingDocument: Bool = false
        var changesMadeToLocalDocument: Bool = false

        for incomingEntry in incomingAccountsDocument.accounts {
            let entryInLocalCopy = getEntryById(incomingEntry.id)
            //log.info ("got local entry \(String(describing: entryInLocalCopy))")
            if entryInLocalCopy != nil {
                //2023-08-21 14:45:30.456789'
                //let dateFormatter = ISO8601DateFormatter()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
                // log.info("formatting from date '\(passwordEntry.lastUpdated)'")
                var lastUpdatedDate: Date? = dateFormatter.date(
                    from: incomingEntry.lastUpdated
                )
                if (lastUpdatedDate == nil) {
                    log.warning(
                        "Missing date in incoming entry '\(incomingEntry.name)', setting it to 1970 ..."
                    )
                    let currentTimeInMillis = Int64(NSDate().timeIntervalSince1970 * 1000)
                    let secondsSince1970 = currentTimeInMillis / 1000
                    lastUpdatedDate = Date(timeIntervalSince1970: TimeInterval(secondsSince1970))
                    //let lastUpdatedDate =
                    //    dateFormatter.string(
                    //        from: date
                    //    )  //  Convert Date to String
                    //if (date == nil) {
                    //    continue
                    //}
                }
                //log.info ("incoming date for \(incomingEntry.name) \(String(describing: lastUpdatedDate))")
                guard
                    let incomingLastUpdatedDate: Date = dateFormatter.date(
                        from: entryInLocalCopy!.lastUpdated
                    )
                else {
                    log.warning(
                        "Missing date in local entry '\(entryInLocalCopy!.name)'"
                    )
                    continue
                }
                if incomingLastUpdatedDate == lastUpdatedDate {
                    log.debug(
                        "dates same for '\(incomingEntry.name)', no updates"
                    )

                } else if incomingLastUpdatedDate < lastUpdatedDate! {
                    log.debug(
                        "incoming, \(incomingEntry.name), later date, replace local entry"
                    )
                    //Task {
                    await replaceEntry(incomingEntry)
                    changesMadeToLocalDocument = true
                    //log.info ("replaced? \(getEntryById(passwordEntry.id))")
                    //}
                } else {
                    log.debug(
                        "local entry, \(entryInLocalCopy!.name), newer, need to update Drive copy .."
                    )
                    changesMadeToIncomingDocument = true
                }
            } else {
                log.debug(
                    "no existing entry for \(incomingEntry.name) in local copy, adding .."
                )
                await addEntry(incomingEntry)
                changesMadeToLocalDocument = true
                //handle new and deleted entries, search Drive version for 'deleted', if not found, we deleted locally
            }
        }

        /** not sure we need to process deleted given we're just going off lastUpdated (over field-by-field comparison)
        log.info("searching for deleted entries ...")
        let deletedEntries = searchDeletedEntries()
        for deletedEntry in deletedEntries {
            log.debug("deleted entry \(deletedEntry)")
        }
        log.info("searching for deleted incoming entries ...")
        let incomingDeleted = searchDeletedEntries(
            providedEntries: incomingAccountsDocument.passwordEntry
        )
        for deletedIncomingEntry in incomingDeleted {
            log.debug("found incoming entry that was deleted \(deletedIncomingEntry)")
            var entryInLocalCopy = getEntryById(deletedIncomingEntry.id)
            entryInLocalCopy?.status = "deleted"  //PasswordEntry.EntryStatus.deleted
        }
         */

        //now loop through local entries and find any missing in Drive version
        //if we find any, they are new and we simply need to ensure we update Drive copy
        for localEntry in accountsDocument.accounts {
            //find in incoming copy, if found, just continue
            if getEntryById(
                localEntry.id,
                providedEntries: incomingAccountsDocument.accounts
            ) != nil {
                continue
            } else {
                //if not found, flag that changes were made
                changesMadeToIncomingDocument = true
            }
        }

        if changesMadeToLocalDocument {
            log.info("saving updates to local copy ...")
            accountsDocument.accounts = entries
            _ = await saveAccountsDocument(
                accountsDocument: self.accountsDocument
            )
        } else {
            log.info("we have latest, no changes made to local copy")
        }
        //if both collections contain same item, take the one with latest timestamp
        //if local has item not in incoming, check for 'deleted' items
        //if deleted, remove item
        //if not in deleted, then add item to latest copy
        //if latest has item not in local, then add it
        //return AccountsDocument(passwordEntry: [])
        return changesMadeToIncomingDocument
    }

    func loadKey() async -> SymmetricKey {
        let settings = await loadSettingsDocument()
        if let keyBase64 = settings?.keyBase64, !keyBase64.isEmpty {
            do {
                // Decode the base64 string to get the raw key data
                if let keyData = Data(base64Encoded: keyBase64) {
                    log.info("Got key from settings: \(keyBase64) ....")
                    // Create a SymmetricKey from the raw key data
                    return SymmetricKey(data: keyData)
                }
            } catch {
                print(
                    "Error creating key from base64: \(error.localizedDescription)"
                )
            }
        }

        // If keyBase64 is empty or there's an error, create a new random key
        print("Using fallback random key")
        return SymmetricKey(size: .bits256)
    }

    /*
     // Encrypt some data
     let originalData = "Secret message".data(using: .utf8)!
     let key = SymmetricKey(size: .bits256)
     let encryptedData = dataManager.encryptData(originalData)
     */
    func encryptData(_ data: Data, key: SymmetricKey? = nil) -> Data {
        // In a real app, you would use a secure key derivation method
        // For this example, we'll use a simple symmetric key
        //let nonce = try! AES.GCM.Nonce(data: Data(String("KeyWith16CharsHe").utf8))
        do {
            let sealedBox = try AES.GCM.seal(data, using: key!)  //, nonce: nonce)
            //let ciphertext = sealedBox.ciphertext.base64EncodedString()
            return sealedBox.combined ?? Data()
        } catch {
            print("Encryption error: \(error.localizedDescription)")
            return Data()
        }
    }

    /*
     // Decrypt the data
     let decryptedData = dataManager.decryptData(encryptedData, key: key)
     let decryptedString = String(data: decryptedData, encoding: .utf8)
     print(decryptedString) // "Secret message"
     */
    func decryptData(_ encryptedData: Data, key: SymmetricKey) -> Data {
        log.info("decryptData(\(String(describing: key))")
        // Use the provided key or create a new one (same as in encryptData)
        // For proper decryption, this should be the same key used for encryption
        //let decryptionKey = key ?? SymmetricKey(size: .bits256)

        do {
            // Create a sealed box from the encrypted data
            // The combined data includes the nonce, ciphertext, and authentication tag
            let nonce = try! AES.GCM.Nonce(
                data: Data(String("KeyWith16CharsHe").utf8)
            )
            let sealedBox = try AES.GCM.seal(
                encryptedData,
                using: key,
                nonce: nonce
            )
            //let sealedBox = try AES.GCM.SealedBox(combined: encryptedData, nonce: nonce)

            // Decrypt the data
            let decryptedData = try AES.GCM.open(
                sealedBox,
                using: key
            )
            return decryptedData
        } catch {
            print("Decryption error: \(error.localizedDescription)")
            return Data()
        }
    }

    /**
     // Get the encryption key
     let key = await dataManager.loadKey()
    
     // Path to an encrypted file
     let encryptedFilePath = documentsDirectory.appendingPathComponent("BytePassData")
         .appendingPathComponent("encrypted_data.json")
    
     // Decrypt the file
     let decryptedData = dataManager.decryptFile(at: encryptedFilePath, key: key)
    
     // Use the decrypted data (e.g., convert to string if it's text)
     if let decryptedString = String(data: decryptedData, encoding: .utf8) {
         print("Decrypted content: \(decryptedString)")
     }
    
     */
    func decryptFile(at filePath: URL, key: SymmetricKey) -> Data {
        do {
            // Read the encrypted data from the file
            let encryptedDataBase64 = try Data(contentsOf: filePath)
            if let encryptedData = Data(base64Encoded: encryptedDataBase64) {

                //let base64EncodedString = String(data: encryptedDataBase64, encoding: .utf8)
                //let base64EncodedData = base64EncodedString?.data(using: .utf8)
                //let data = Data(base64Encoded: base64EncodedData)
                //let encryptedData = Data(base64Encoded: encryptedDataBase64)
                //try Base64Decoder().decode(base64EncodedString)
                log.info("loaded encrypted file \(filePath) ...")
                // Use the existing decryptData function to decrypt the data
                let decryptedData = decryptData(encryptedData, key: key)
                print("decrypted file data ...")
                return decryptedData
            }
        } catch {
            print(
                "Error decrypting file at \(filePath.path): \(error.localizedDescription)"
            )
            return Data()
        }
        return Data()
    }

    func getAllTags() -> [String] {
        let allTags = searchActiveEntries().flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    func searchEntries(query: String) -> [Account] {
        guard !query.isEmpty else { return searchActiveEntries() }

        let lowercasedQuery = query.lowercased()
        searchResults = entries.filter { entry in
            entry.name.lowercased().contains(lowercasedQuery)
                || entry.username.lowercased().contains(lowercasedQuery)
                || entry.password.lowercased().contains(lowercasedQuery)
                || entry.accountNumber.lowercased().contains(lowercasedQuery)
                || entry.url.lowercased().contains(lowercasedQuery)
                || entry.email.lowercased().contains(lowercasedQuery)
                || entry.hint.lowercased().contains(lowercasedQuery)
                || entry.notes.lowercased().contains(lowercasedQuery)
                || entry.tags.contains {
                    $0.lowercased().contains(lowercasedQuery)
                }
                    && entry.status == "active"
        }.sorted { $0.name < $1.name }
        return searchResults
    }

    func searchDeletedEntries(providedEntries: [Account]? = nil)
        -> [Account]
    {
        let toSearch = providedEntries ?? entries
        return toSearch.filter { entry in
            entry.status == "deleted"  //PasswordEntry.EntryStatus.deleted
        }
    }

    func searchActiveEntries(providedEntries: [Account]? = nil)
        -> [Account]
    {
        let toSearch = providedEntries ?? entries
        return toSearch.filter { entry in
            entry.status == "active"
        }
    }

    func filterByTag(tag: String) -> [Account] {
        log.info("filtering on tag \(tag) with \(entries.count) entries")
        return entries.filter { entry in
            entry.tags.contains(tag)
                && entry.status == "active"
        }.sorted { $0.name < $1.name }
    }

    func sortedByName() -> [Account] {
        return entries.sorted { $0.name < $1.name }
    }

    func accessDocumentExists() -> Bool {
        let accessFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )
        .appendingPathComponent("access.json")

        // Check if the file exists
        return fileManager.fileExists(atPath: accessFilePath.path)
    }

    func loadAccessDocument() async -> (AccessDocument?, Data?) {
        let accessFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )
        .appendingPathComponent("access.json")

        // Check if the file exists
        if fileManager.fileExists(atPath: accessFilePath.path) {
            do {
                let data = try Data(contentsOf: accessFilePath)
                let decoder = JSONDecoder()
                let accessDocument = try decoder.decode(
                    AccessDocument.self,
                    from: data
                )
                return (accessDocument, data)
            } catch {
                print(
                    "Error loading access.json: \(error.localizedDescription)"
                )
                return await createNewAccessDocument()
            }
        } else {
            // Create a new access document if it doesn't exist
            return await createNewAccessDocument()
        }
    }

    /**
    func saveAccessDocument(accessDocument: AccessDocument) {
        do {
            // Save the new access document
            // Create the BytePassData directory if it doesn't exist
            let dataDirectory = documentsDirectory.appendingPathComponent(
                "BytePassData",
                isDirectory: true
            )
            let accessFilePath = dataDirectory.appendingPathComponent(
                "access.json"
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(accessDocument)
            try data.write(to: accessFilePath, options: .atomic)
            log.info("Created new access.json at: \(accessFilePath.path)")
        } catch {
            print("Error saving access.json: \(error.localizedDescription)")
        }
    }
     ***/

    func createNewAccountsDocument() async -> (AccountsDocument?, Data?) {
        // Create a new access document with current timestamp
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withFullDate, .withTime, .withDashSeparatorInDate,
            .withColonSeparatorInTime, .withFractionalSeconds,
        ]
        let currentTimeInMillis = Int64(NSDate().timeIntervalSince1970 * 1000)
        //let timeInterval = Date().timeIntervalSince1970
        //let timestamp = dateFormatter.string(from: Date())
        let accountsDocument = AccountsDocument(
            lastUpdated: String(currentTimeInMillis),
            accounts: []
        )
        return await saveAccountsDocument(accountsDocument: accountsDocument)
    }

    func saveCurrentAccountsDocument() async -> (
        AccountsDocument?, Data?
    ) {
        self.accountsDocument.accounts = entries
        let currentTimeInMillis = Int64(NSDate().timeIntervalSince1970 * 1000)
        accountsDocument.lastUpdated = String(currentTimeInMillis)
        return await saveAccountsDocument(
            accountsDocument: self.accountsDocument
        )
    }

    func saveAccountsDocument(accountsDocument: AccountsDocument) async -> (
        AccountsDocument?, Data?
    ) {
        // Create the BytePassData directory if it doesn't exist
        let dataDirectory = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )

        do {
            if !fileManager.fileExists(atPath: dataDirectory.path) {
                try fileManager.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
            }

            // Save the new access document
            let accountsFilePath = dataDirectory.appendingPathComponent(
                "accounts.json"
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(accountsDocument)
            try data.write(to: accountsFilePath, options: .atomic)

            log.info("Saving local accounts at: \(accountsFilePath.path)")
            return (accountsDocument, data)
        } catch {
            print("Error saving accounts.json: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    func createNewAccessDocument() async -> (AccessDocument?, Data?) {
        // Create a new access document with current timestamp
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withFullDate, .withTime, .withDashSeparatorInDate,
            .withColonSeparatorInTime, .withFractionalSeconds,
        ]
        let timestamp = dateFormatter.string(from: Date())
        let accessDocument = AccessDocument(
            lastUpdated: timestamp,
            clients: []
        )
        return await saveAccessDocument(accessDocument: accessDocument)
    }

    func saveAccessDocument(accessDocument: AccessDocument) async -> (
        AccessDocument?, Data?
    ) {
        // Create the BytePassData directory if it doesn't exist
        let dataDirectory = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )

        do {
            if !fileManager.fileExists(atPath: dataDirectory.path) {
                try fileManager.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
            }

            // Save the new access document
            let accessFilePath = dataDirectory.appendingPathComponent(
                "access.json"
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(accessDocument)
            try data.write(to: accessFilePath, options: .atomic)

            log.info("Saving local access.json at: \(accessFilePath.path)")
            return (accessDocument, data)
        } catch {
            print("Error saving access.json: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    func loadSettingsDocument() async -> SettingsDocument? {
        log.debug("loading local settings document ...")
        let settingsFilePath = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )
        .appendingPathComponent("settings.json")

        // Check if the file exists
        if fileManager.fileExists(atPath: settingsFilePath.path) {
            do {
                let data = try Data(contentsOf: settingsFilePath)
                log.debug(
                    "loaded local settings file: \(String(describing: data))"
                )
                let decoder = JSONDecoder()
                let settingsDocument = try decoder.decode(
                    SettingsDocument.self,
                    from: data
                )
                return settingsDocument
            } catch {
                print(
                    "Error loading settings.json: \(error.localizedDescription)"
                )
                return createNewSettingsDocument()
            }
        } else {
            // Create a new settings document if it doesn't exist
            return createNewSettingsDocument()
        }
    }

    private func createNewSettingsDocument() -> SettingsDocument? {
        // Create a new settings document with current timestamp
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withFullDate, .withTime, .withDashSeparatorInDate,
            .withColonSeparatorInTime, .withFractionalSeconds,
        ]
        let timestamp = dateFormatter.string(from: Date())

        let authClient = AuthClientDocument(
            lastUpdated: timestamp,
            data: "",
            type: "Bearer",
            expiry: timestamp,
            refreshToken: ""
        )
        let settingsDocument = SettingsDocument(
            //lastUpdated: timestamp,
            keyBase64: "",
            clientId: timestamp,
            authClient: authClient
        )

        // Create the BytePassData directory if it doesn't exist
        let dataDirectory = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )

        do {
            if !fileManager.fileExists(atPath: dataDirectory.path) {
                try fileManager.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
            }

            // Save the new access document
            let settingsFilePath = dataDirectory.appendingPathComponent(
                "settings.json"
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settingsDocument)
            try data.write(to: settingsFilePath, options: .atomic)

            print("Created new settings.json at: \(settingsFilePath.path)")
            return settingsDocument
        } catch {
            print("Error creating settings.json: \(error.localizedDescription)")
            return nil
        }
    }

    func saveSettingsDocument(_ settingsDocument: SettingsDocument) async
        -> Bool
    {
        let dataDirectory = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )
        let settingsFilePath = dataDirectory.appendingPathComponent(
            "settings.json"
        )

        do {
            if !fileManager.fileExists(atPath: dataDirectory.path) {
                try fileManager.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settingsDocument)
            try data.write(to: settingsFilePath, options: .atomic)

            print("Saved settings.json to: \(settingsFilePath.path)")
            return true
        } catch {
            print("Error saving settings.json: \(error.localizedDescription)")
            return false
        }
    }

}
