//
// ResultsView
//
// This view is a list of search results based on either
// a free text search or all items associated with a tag.
//

import Logging
import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
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
        if showLoadingScreen {
            Text("Loading ...")
        } else if results.isEmpty {
            Text("No Results")
        } else {
            NavigationStack {
                List {
                    ForEach(results) { entry in
                        NavigationLink(
                            destination: AccountDetailView(
                                selectedAccount: entry,
                                results: $results
                            )
                        ) {
                            ListEntryView(accountEntry: entry)
                        }.listRowBackground(Color.clear)
                    }
                }
                .listRowSpacing(10.0)
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("\(filterType)").foregroundColor(
                    getForegroundColor()
                )
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(getForegroundColor())
            }
        }
    }
    func getForegroundColor() -> Color {
        return colorScheme == .dark ? darkForegroundColor : lightForegroundColor
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
