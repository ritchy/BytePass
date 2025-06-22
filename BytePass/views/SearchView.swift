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
    @State private var showingResults = false
    @State private var showSearchingScreen: Bool = false
    @State private var isPresentingNewAccountView: Bool = false
    @FocusState private var searchIsFocused: Bool
    @State var newAccount: Account = Account.emptyAccount

    var resultsView: ResultsView?

    @Environment(\.dismiss) private var dismiss

    let log = Logger(label: "io.bytestream.bytepass.SearchView")

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 10)
        //GridItem(.fixed(100), spacing: 10)
    ]

    init() {
    }

    var body: some View {
        if showSearchingScreen {
            Text("Searching ...")
        } else if showSyncingScreen {
            Text("Syncing ...")
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
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true).onSubmit {
                        performSearch()
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button() {
                                searchIsFocused = false
                            }
                            label: {
                                Text ("Dismiss")
                                Image(systemName: "keyboard.chevron.compact.down")
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
                        .cornerRadius(10)
                }.disabled(searchText.isEmpty)
            }.padding(.horizontal)

            Text("Filter by Tags")
                .font(.headline)
                .padding(.top)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    Button(action: {
                        //.authenticationState = .authenticated
                        showSearchingScreen = true
                        selectedTag = "all"
                        searchResults = dataManager.sortedByName()
                        numberOfResults = searchResults.count
                        showSearchingScreen = false
                        showingResults = true
                    }) {
                        Text("all")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            //.background (background(Color.blue.opacity(0.7)))
                            //.background(Color.primary)
                            .cornerRadius(8)
                    }
                    ForEach(dataManager.getAllTags(), id: \.self) { tag in
                        Button(action: {
                            selectedTag = tag
                            showSearchingScreen = true
                            searchResults = dataManager.filterByTag(tag: tag)
                            log.info("search results \(searchResults.count)")
                            showSearchingScreen = false
                            showingResults = true
                        }) {
                            Text(tag)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                //.foregroundColor(Color.accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                //.background(Color.primary)
                                //.background (background(Color.blue.opacity(0.7)))
                                .cornerRadius(8)
                        }  //.clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding()
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
            signInWithGoogleService()
        } else if await googleService.isSignedIn() {
            log.info("signed in, syncing with google drive ...")
            await googleService.handleSync()
        } else {
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

    }

    private func signInWithGoogleService() {
        Task {
            //let googleService = GoogleService()
            try await googleService.signIn()
            dismiss()
        }
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
        Button(action: { authViewModel.signOut() }) {
            Text("Signout")
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
        }
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
