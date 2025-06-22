import Logging
import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var results: [Account] = []
    @State private var showingEntryDetails: Bool = false
    @State private var showLoadingScreen: Bool = false

    let filterType: String
    let log = Logger(label: "io.bytestream.bytepass.ResultsView")

    public init(
        results: [Account],
        filterType: String
    ) {
        self.results = results
        self.filterType = filterType
        log.info("Showing results for \(filterType)")
    }

    var body: some View {
        if (showLoadingScreen) {
            Text("Loading ...")
        }else if (results.isEmpty) {
            Text("No Results")
        } else {
            NavigationStack {
                List {
                    ForEach(results) { entry in
                        NavigationLink(
                            destination: AccountDetailView(selectedAccount: entry, results: $results)
                        ) {
                            EntryView(accountEntry: entry)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("\(filterType)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct EntryView: View {
    let accountEntry: Account
    init(accountEntry: Account) {
        self.accountEntry = accountEntry
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(accountEntry.name)
                    .font(.headline)

                HStack {
                    Text("Username:")
                        .fontWeight(.medium)
                    Text(accountEntry.username)
                }
                if !accountEntry.accountNumber.isEmpty {
                    HStack {
                        Text("Account:")
                            .fontWeight(.medium)
                        Text(accountEntry.accountNumber)
                    }
                }

                if !accountEntry.url.isEmpty {
                    HStack {
                        Text("URL:")
                            .fontWeight(.medium)
                        Text(accountEntry.url)
                    }
                }

                if !accountEntry.email.isEmpty {
                    HStack {
                        Text("Email:")
                            .fontWeight(.medium)
                        Text(accountEntry.email)
                    }
                }

                if !accountEntry.hint.isEmpty {
                    HStack {
                        Text("Hint:")
                            .fontWeight(.medium)
                        Text(accountEntry.hint)
                    }
                }

                if !accountEntry.notes.isEmpty {
                    Text("Notes:")
                        .fontWeight(.medium)
                    Text(accountEntry.notes)
                        .font(.subheadline)
                        .padding(.leading, 8)
                }

                if !accountEntry.tags.isEmpty {
                    HStack {
                        Text("Tags:")
                            .fontWeight(.medium)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(accountEntry.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Color.blue.opacity(0.2)
                                        )
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
        }.padding(.vertical, 8)

    }
}

#Preview {
    NavigationView {
        ResultsView(
            results: [
                Account(
                    name: "Acme Login",
                    lastUpdated: "2023-08-18 14:00:25.065893",
                    status: "active",
                    id: 1_665_509_765_428,
                    username: "ritchy",
                    password: "password213",
                    accountNumber: "123-P-234",
                    url: "https://acme.com",
                    email: "",
                    hint: "dinner",
                    notes: "This is for buying all my tools",
                    tags: ["finance", "tools"]
                )
            ],
            filterType: "Tag: finance"
        )
    }
}
