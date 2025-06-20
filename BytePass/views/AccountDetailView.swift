//
//  DetailView.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/3/25.
//

import Logging
import SwiftUI

struct AccountDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var selectedAccount: Account
    @State private var isPresentingEditView = false
    @Binding var results: [Account]

    let log = Logger(label: "io.bytestream.bytepass.AccountDetailView")

    //public init(
    //    selectedAccount: Account
    //) {
    //    self.selectedAccount = selectedAccount
    //}

    var body: some View {
        VStack(alignment: .center) {
            Label(selectedAccount.name, systemImage: "storefront")
            List {
                Section(
                    header: Label(
                        "Account Information",
                        systemImage: "storefront"
                    )
                ) {

                    HStack {
                        Text("Account Name:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.name)
                    }

                    HStack {
                        Text("Account Number:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.accountNumber)
                    }

                    HStack {
                        Text("URL:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.url)
                    }

                }
                Section(
                    header: Label("Personal Information", systemImage: "person")
                ) {
                    HStack(alignment: .center) {
                        Text("Username:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.username)
                    }
                    HStack {
                        Text("Password:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.password)
                    }
                    HStack {
                        Text("Email:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.email)
                    }
                    HStack {
                        Text("Hint:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedAccount.hint)
                    }

                }
                Section(
                    header: Label(
                        "Notes",
                        systemImage: "note.text"
                    )
                ) {
                    VStack(alignment: .leading) {
                        Text(selectedAccount.notes)
                            .font(.subheadline)
                            .padding(.leading, 8)

                    }
                }
                Section(
                    header: Label(
                        "Tags",
                        systemImage: "tag"
                    )
                ) {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedAccount.tags, id: \.self) {
                                    tag in
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
        }
        .padding(.all, 8)
        .toolbar {
            Button("Edit") {
                isPresentingEditView = true
            }
        }
        .sheet(
            isPresented: $isPresentingEditView,
            onDismiss: {
                log.info("onDismiss")
            }
        ) {
            NavigationStack {
                AccountEditView(selectedAccount: $selectedAccount)
                    //.navigationTitle(selectedAccount.name)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isPresentingEditView = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingEditView = false
                                log.info(
                                    "results count: \(dataManager.searchResults.count)"
                                )
                                let orig = dataManager.getEntryById(
                                    selectedAccount.id
                                )
                                log.info("orig \(orig?.name ?? "nil")")
                                if orig != selectedAccount {
                                    log.info(
                                        "account changed, need to save ..."
                                    )
                                    //orig?.hint = "hinttty"
                                    //var x = dataManager.searchResults.first
                                    //x?.hint = "hinttty"
                                    let index = results.firstIndex(where: {
                                        $0.id == selectedAccount.id
                                    })
                                    if index != nil {
                                        var toSave = selectedAccount
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat =
                                            "yyyy-MM-dd HH:mm:ss.SSSSSS"
                                        let currentDate = Date()
                                        let formattedDateString =
                                            dateFormatter.string(
                                                from: currentDate
                                            )  //  Convert Date to String
                                        //print(formattedDateString)
                                        let currentTimeInMillis = Int64(
                                            NSDate().timeIntervalSince1970
                                                * 1000
                                        )
                                        let secondsSince1970 =
                                            currentTimeInMillis / 1000
                                        let date = Date(
                                            timeIntervalSince1970: TimeInterval(
                                                secondsSince1970
                                            )
                                        )
                                        //print ("----> \(date)")
                                        //toSave.lastUpdated = String(currentTimeInMillis)
                                        toSave.lastUpdated = formattedDateString
                                        log.info(
                                            "new updated date: \(formattedDateString) - \(toSave.lastUpdated)"
                                        )
                                        results[index!] = toSave
                                        log.info(
                                            "new updated date: \(formattedDateString) - \(toSave.lastUpdated)"
                                        )
                                        Task {
                                            await dataManager.replaceEntry(
                                                toSave
                                            )
                                            _ =
                                                await dataManager
                                                .saveCurrentAccountsDocument()
                                        }
                                    }
                                } else {
                                    log.info("nothing changed, no need to save")
                                }
                            }
                        }
                    }
            }
        }
    }
}
