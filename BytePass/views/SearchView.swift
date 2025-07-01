//import FirebaseAnalytics
import GoogleDriveClient
import Logging
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var googleService: GoogleService
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var searchResults: [Account] = []
    @State private var currentSearchText = ""
    @State private var numberOfResults: Int = 0
    @State private var showSyncingScreen: Bool = false
    @State private var showSignOutScreen: Bool = false
    @State private var showingResults = false
    @State private var showSearchingScreen: Bool = false
    @State private var isPresentingNewAccountView: Bool = false
    @State private var signedIn: Bool = false
    @FocusState private var searchIsFocused: Bool
    @State var newAccount: Account = Account.emptyAccount

    var resultsView: ResultsView?

    @Environment(\.dismiss) private var dismiss

    let log = Logger(label: "io.bytestream.bytepass.SearchView")

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 190), spacing: 10)
        //GridItem(.flexible(minimum: 150, maximum: 180), spacing: 0)
        //GridItem(.fixed(100), spacing: 10)
    ]

    init() {
    }

    var body: some View {
        if showSearchingScreen {
            Text("Searching ...")
        } else if showSyncingScreen {
            Text("Syncing ...")
        } else if showSignOutScreen {
            Text("Signing out ...")
        } else {
            searchView()
        }
    }

    func performSearch() {
        showSearchingScreen = true
        searchResults = dataManager.searchEntries(query: searchText)
        log.info("search results \(searchResults.count)")
        currentSearchText = searchText
        searchText = ""
        showSearchingScreen = false
        showingResults = true
    }

    func searchView() -> some View {
        VStack(spacing: 20) {
            if (dataManager.entries.isEmpty) {
                Spacer()
                Button {
                    isPresentingNewAccountView = true
                } label: {
                    NoEntryView()
                }
                Spacer()
            }
            else {
                HStack {
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true).onSubmit {
                            performSearch()
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button {
                                    searchIsFocused = false
                                } label: {
                                    Text("Dismiss")
                                    Image(
                                        systemName: "keyboard.chevron.compact.down"
                                    )
                                }
                            }
                        }
                        .focused($searchIsFocused)
                    Button(action: {
                        performSearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                        //.background(Color.primary)
                    }.disabled(searchText.isEmpty)
                        .cornerRadius(10)
                }.padding(.horizontal)
                .padding([.top], 20)
                
                Text("Filter by Tags")
                    .font(.headline)
                    .padding(0)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        Button(
                            action: {
                                showSearchingScreen = true
                                selectedTag = "all"
                                searchResults = dataManager.sortedByName()
                                numberOfResults = searchResults.count
                                showSearchingScreen = false
                                showingResults = true
                            },
                            label: {
                                TagButtonView(
                                    text: "all",
                                    itemCount: String(dataManager.entries.count)
                                )
                            }
                        )
                        ForEach(dataManager.getAllTags(), id: \.self) { tag in
                            let results = dataManager.filterByTag(tag: tag)
                            //print ("result count for \(tag) is \(results.count)")
                            Button(
                                action: {
                                    selectedTag = tag
                                    showSearchingScreen = true
                                    searchResults = dataManager.filterByTag(
                                        tag: tag
                                    )
                                    log.debug(
                                        "pre searching search results \(searchResults.count)"
                                    )
                                    showSearchingScreen = false
                                    showingResults = true
                                },
                                label: {
                                    TagButtonView(
                                        text: tag,
                                        itemCount: String(results.count)
                                    )
                                }
                            )
                        }
                    }.padding()
                }
            }
            Spacer()
        }
        //.background(Color.green)
        //.padding()
        .navigationTitle("BytePass")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                syncButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                signOutButton()
            }
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Button {
                        isPresentingNewAccountView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

        }
        .sheet(
            isPresented: $isPresentingNewAccountView,
            onDismiss: {
                log.info("onDismiss of new account view")
                isPresentingNewAccountView = false

            }
        ) {
            NavigationStack {
                AccountEditView(selectedAccount: $newAccount)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isPresentingNewAccountView = false
                                newAccount = Account.emptyAccount
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingNewAccountView = false
                                Task {
                                    if newAccount.isValid() {
                                        await dataManager.addEntry(newAccount)
                                        _ =
                                            await dataManager
                                            .saveCurrentAccountsDocument()
                                        newAccount = Account.emptyAccount
                                    } else {
                                        log.info(
                                            "not a valid account, not adding .."
                                        )
                                    }
                                    newAccount = Account.emptyAccount
                                }
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showingResults) {
            NavigationStack {
                ResultsView(
                    results: searchResults,
                    filterType: selectedTag != nil
                        ? "Tagged with \(selectedTag!)"
                        : "Searched for \(currentSearchText)"
                )
                //.onAppear() {
                //    log.info ("ResultsView appearing ..")
                //    refresh()
                //}
                .environmentObject(dataManager)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Home") {
                            showingResults = false
                            selectedTag = nil
                        }
                    }
                }
            }
        }.onAppear {
            Task {
                searchResults = dataManager.sortedByName()
                numberOfResults = searchResults.count
                await checkSignedIn()
            }
        }
        //.analyticsScreen(name: "\(SearchView.self)")

    }
    private func handleSync() async {
        googleService.dataManager = dataManager
        log.info("handleSync")
        //log.info(
        //    "dm accounts \(dataManager.entries.count) - \(dataManager.accountsDocument.passwordEntry.count)"
        //)

        //@TODO
        // first, try loading our settings for any google token and data encryption key
        //let settingsDocument = await dataManager.loadSettingsDocument()
        //log.info("key in settings: \(String(describing: settingsDocument?.keyBase64))")

        // if there is no encryption key, we need to request access to Drive
        // load our access file to add our request for access
        //let accessDocument = await dataManager.loadAccessDocument()
        //print ("loaded access document \(String(describing: accessDocument))")

        // otherwise, if there is an encyption key, then load our access file to check for anyone else requesting access

        if await !googleService.isSignedIn() {
            //await googleService.handleSync()
            log.info(
                "not signed in, need to sign into google drive ..."
            )
            await signInWithGoogleService()
            //await googleService.handleSync()
        }

        if await googleService.isSignedIn() {
            log.info("signed in, syncing with google drive ...")
            await googleService.handleSync()
        } else {
            log.info("logged out, skipping syncing for now")
        }

    }

    private func signInWithAuth() async {
        switch authViewModel.state {
        case .signedIn:
            log.info(
                "signed in through googlesignIn, syncing with google drive ..."
            )
            await googleService.handleSync()
        case .signedOut:
            log.info("need to sign into google ..")
            do {
                try await googleService.signIn()
            } catch {
                log.error(
                    "googleservice signin failure",
                    metadata: [
                        "error": "\(error)",
                        "localizedDescription":
                            "\(error.localizedDescription)",
                    ]
                )
            }
        //authViewModel.signIn()
        }
    }

    private func signInWithGoogleService() async {
        //let googleService = GoogleService()
        do {
            try await googleService.signIn()
        } catch {
            log.error(
                "googleservice signin failure",
                metadata: [
                    "error": "\(error)",
                    "localizedDescription":
                        "\(error.localizedDescription)",
                ]
            )
        }
        await checkSignedIn()
        //dismiss()
    }

    private func signOutWithGoogleService() {
        showSignOutScreen = true
        Task {
            try await googleService.signOut()
            try await Task.sleep(nanoseconds: 350_000_000)
            await checkSignedIn()
            showSignOutScreen = false
        }
    }

    private func checkSignedIn() async {
        signedIn = await googleService.isSignedIn()
    }

    func syncButton() -> some View {
        Button(action: {
            showSyncingScreen = true
            Task {
                await handleSync()
                showSyncingScreen = false
            }
        }) {
            Text("Sync")
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
        }
        .onOpenURL { url in
            Task<Void, Never> {
                do {
                    log.info("handling REDIRECT ...")
                    _ = try await googleService.handleRedirect(url: url)
                    await checkSignedIn()
                    //log.info("back from redirect? logged in? \(signedIn)")
                    if signedIn {
                        log.info(
                            "now we signed in! syncing with google drive ..."
                        )
                        await googleService.handleSync()
                    } else {
                        log.info(
                            "still logged out after redirect, skipping sync this time"
                        )
                    }
                } catch {
                    log.error(
                        "Auth.HandleRedirect failure",
                        metadata: [
                            "error": "\(error)",
                            "localizedDescription":
                                "\(error.localizedDescription)",
                        ]
                    )
                }
            }
        }
    }

    func signOutButton() -> some View {
        Button(action: { signOutWithGoogleService() }) {
            Text("Signout")
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
        }.disabled(signedIn == false)
    }

}

#Preview {
    NavigationView {
        SearchView()
            .environmentObject(
                {
                    let manager = DataManager(previewMode: true)
                    return manager
                }()
            )
    }
}
