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
    @Environment(\.dismiss) private var dismiss
    @State var selectedAccount: Account
    @State var passwordText: String = "********"
    @State private var isPresentingEditView = false
    @State var isDeleted: Bool = false
    @Binding var results: [Account]
    
    @State var messageToShow: String = "tap any field to copy"

    let log = Logger(label: "io.bytestream.bytepass.AccountDetailView")

    func considerDismiss() {
        if selectedAccount.status == "deleted" {
            Task {
                await deleteSelectedItem()
            }
        }
    }

    func deleteSelectedItem() async {
        log.info("deleting...")
        await MainActor.run {
            dataManager.deleteEntry(selectedAccount)
            isDeleted = true
        }
        Task {
            await _ = dataManager.saveCurrentAccountsDocument()
        }
    }
    
    var body: some View {
        if isDeleted {
            VStack {
                Button("\(selectedAccount.name) deleted") {
                    results.removeAll(where: {
                        $0.id == selectedAccount.id
                    })
                    dismiss()
                }
            }
        } else {
            getMainView()
        }
    }

    func handleCopy(fieldName:String, textToCopy: String) {
        if textToCopy.isEmpty || fieldName.isEmpty {
            showMessage(message: "tap any field to copy")
            return
        }

        let pasteboard = UIPasteboard.general
        pasteboard.string = textToCopy
        showMessage(message: "\(fieldName) copied to clipboard")
    }

    func showMessage(message: String) {
        messageToShow = message
    }

    func getMainView() -> some View {
        VStack(alignment: .center) {
            VStack {
                Label(selectedAccount.name, systemImage: "storefront").padding([.bottom],12).font(.headline)
                Text(messageToShow) //, systemImage: "doc.on.clipboard")
                    .fontWeight(.light).font(.caption)
            }
            List {
                Section(
                    header: Label(
                        "Account Information",
                        systemImage: "storefront"
                    )
                ) {

                    HStack {
                        Text("Account Name:")
                            .fontWeight(.light).font(.subheadline)
                        Spacer()
                        Text(selectedAccount.name)//.fontWeight(.bold).font(.body)
                    }.onTapGesture {
                        handleCopy(fieldName: "Account Name", textToCopy: selectedAccount.name)
                    }

                    HStack {
                        Text("Account Number:")
                            .fontWeight(.light).font(.subheadline)
                        Spacer()
                        Text(selectedAccount.accountNumber)
                    }.onTapGesture {
                        handleCopy(fieldName: "Account Number", textToCopy: selectedAccount.accountNumber)
                    }

                    HStack {
                        Text("URL:")
                            .fontWeight(.light).font(.subheadline)
                        Spacer()
                        Text(selectedAccount.url)
                    }.onTapGesture {
                        handleCopy(fieldName: "Account URL", textToCopy: selectedAccount.url)
                    }

                }
                Section(
                    header: Label(
                        "Personal Information",
                        systemImage: "person"
                    )
                ) {
                    HStack(alignment: .center) {
                        Text("Username:")
                            .fontWeight(.light).font(.subheadline)
                        Spacer()
                        Text(selectedAccount.username)
                    }.onTapGesture {
                        handleCopy(fieldName: "Username", textToCopy: selectedAccount.username)
                    }

                    HStack {
                        Text("Password:")
                            .fontWeight(.light).font(.subheadline).background(Color.yellow)
                        Spacer().background(Color.green).onTapGesture {
                            handleCopy(fieldName: "Password", textToCopy: selectedAccount.password)
                        }
                        Text(passwordText).privacySensitive().background(Color.blue)
                    }.onTapGesture {
                        handleCopy(fieldName: "Password", textToCopy: selectedAccount.password)
                    }.background(Color.indigo)

    
                    HStack {
                        Text("Email:")
                            .fontWeight(.light).font(.subheadline)
                        Spacer()
                        Text(selectedAccount.email)
                    }.onTapGesture {
                        handleCopy(fieldName: "Email", textToCopy: selectedAccount.email)
                    }

                    HStack {
                        Text("Hint:")
                            .fontWeight(.light).font(.subheadline)
                        Spacer()
                        Text(selectedAccount.hint)
                    }.onTapGesture {
                        handleCopy(fieldName: "Hint", textToCopy: selectedAccount.hint)
                    }

                }.onLongPressGesture(
                    minimumDuration: 0.5,
                    maximumDistance: 50,
                    perform: {
                        passwordText = selectedAccount.password
                    },
                    onPressingChanged: { pressing in
                        passwordText = "********"
                    }
                )
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
                }.onTapGesture {
                    handleCopy(fieldName: "Notes", textToCopy: selectedAccount.notes)
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
        .onAppear {
            log.debug("onAppear() .. consider dismissing ..")
            considerDismiss()
        }
        .padding(.all, 8)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isPresentingEditView = true
                }
            }
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .center) {
                    Spacer()
                    DeleteEntryButton(
                        selectedAccount: $selectedAccount,
                        isDeleted: $isDeleted
                    )
                    Spacer()
                }
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
                                        let toSave = selectedAccount
                                        results[index!] = toSave
                                        Task {
                                            await dataManager.updateEntry(
                                                toSave
                                            )
                                            _ =
                                                await dataManager
                                                .saveCurrentAccountsDocument()
                                        }
                                    }
                                } else {
                                    log.info(
                                        "nothing changed, no need to save"
                                    )
                                }
                            }
                        }
                    }
            }
        }

    }

    struct DeleteEntryButton: View {
        @EnvironmentObject var dataManager: DataManager
        @State private var showPopup = false
        @Binding var selectedAccount: Account
        @Binding var isDeleted: Bool

        let log = Logger(label: "io.bytestream.bytepass.DeleteEntryButton")

        var body: some View {
            Button {
                print("delete ..")
                self.showPopup = true
            } label: {
                Text("Delete")
                Image(systemName: "trash")
            }
            .alert("Confirm Delete", isPresented: $showPopup) {
                Button(role: .destructive) {
                    // Handle the deletion.
                    Task {
                        await deleteSelectedItem()
                        isDeleted = true
                    }
                } label: {
                    Text("Yes, Delete")
                }
            } message: {
                Text("Are you sure you want to delete \(selectedAccount.name)?")
            }
        }

        func deleteSelectedItem() async {
            log.info("deleting...")
            await MainActor.run {
                dataManager.deleteEntry(selectedAccount)
            }
            Task {
                await _ = dataManager.saveCurrentAccountsDocument()
            }
        }

        func cancelDelete() {
            log.info("Canceling...")
        }
    }
}
