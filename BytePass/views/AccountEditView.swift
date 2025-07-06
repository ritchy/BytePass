//
//  AccountEditView.swift
//
//
//  This view is basically a form showing all the potential
//  Account entry values, allowing user to update and save.
//

import Logging
import SwiftUI

struct AccountEditView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedAccount: Account
    @State var isPresentingTagView: Bool = false
    @State var showPassword: Bool = false
    
    let log = Logger(label: "io.bytestream.bytepass.AccountEditView")

    /**
     var name: String
     var lastUpdated: String
     var status: String
     var id: Int
     var username: String
     var password: String
     var accountNumber: String
     var url: String
     var email: String
     var hint: String
     var notes: String
     var tags: [String]
     */
    var body: some View {
        VStack {
            Label(selectedAccount.name, systemImage: "storefront")
            Form {
                List {
                    Section(
                        header: Label(
                            "Account Information",
                            systemImage: "storefront"
                        ).foregroundColor(colorScheme == .dark ? darkForeground : lightForeground)

                    ) {
                        getTextField(placeholder: "Account Name", text: $selectedAccount.name)
                        getTextField(
                            placeholder: "Account Number",
                            text: $selectedAccount.accountNumber)
                        getTextField(placeholder: "URL", text: $selectedAccount.url).onSubmit {
                            log.info("url -> \($selectedAccount.url)")
                        }
                    }
                    Section(
                        header: Label(
                            "Personal Information",
                            systemImage: "person"
                        ).foregroundColor(colorScheme == .dark ? darkForeground : lightForeground)
                    ) {
                        getTextField(placeholder: "Username", text: $selectedAccount.username)
                        HStack {
                            if showPassword {
                                getTextField(placeholder: "Password", text: $selectedAccount.password)
                            } else {
                                SecureField("Password", text: $selectedAccount.password,
                                prompt: Text("Password").foregroundColor(colorScheme == .dark ? darkPlaceholderColor : lightPlaceholderColor))

                            }
                            Spacer()
                            Button(action: {
                                showPassword = !showPassword
                            }) {
                                let imageName = showPassword ? "eye" : "eye.slash"
                                Image (systemName: imageName)
                            }
                        }
                        getTextField(placeholder: "Email", text: $selectedAccount.email).keyboardType(.emailAddress)
                        getTextField(placeholder: "Hint", text: $selectedAccount.hint).scrollDismissesKeyboard(.immediately)
                    }
                    Section(
                        header: Label(
                            "Notes",
                            systemImage: "note.text"
                        ).foregroundColor(colorScheme == .dark ? darkForeground : lightForeground)
                    ) {
                        TextField(
                            "Notes",
                            text: $selectedAccount.notes,
                            prompt: Text("Notes").foregroundColor(getPlaceholderColor()),
                            axis: .vertical,
                        ).lineLimit(3, reservesSpace: true).onSubmit {
                            log.info("notes -> \($selectedAccount.notes)")
                        }
                    }
                    Section(
                        header: Label(
                            "Tags",
                            systemImage: "tag"
                        ).foregroundColor(colorScheme == .dark ? darkForeground : lightForeground)
                    ) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Button("<manage>") {
                                    isPresentingTagView = true
                                }.foregroundColor(colorScheme == .dark ? darkForeground : lightForeground)

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
                        //Text("Tags", text: "\(String(describe: selectedAccount.tags))")
                    }
                }
            }.onSubmit {
                log.info("form submitted .. \($selectedAccount)")
            }
        }.sheet(
            isPresented: $isPresentingTagView,
            onDismiss: {
                log.info("onDismiss of tag editor view \(selectedAccount.tags)")
            }
        ) {
            NavigationStack {
                
                TagEditorView(selectedAccount: $selectedAccount, viewModel: TagEditorViewModel(selectedTags: selectedAccount.tags, allTags: dataManager.getAllTags(), selectedAccount: $selectedAccount)).onDisappear {
                    log.info(
                        "onDisappear of tag editor view \(selectedAccount.tags)"
                    )
                }.toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            log.info(
                                "cancel of tag editor view \(selectedAccount.tags)"
                            )
                            isPresentingTagView = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            log.info(
                                "done button selected for tag editor view \(selectedAccount.tags)"
                            )
                            isPresentingTagView = false
                        }
                    }
                }
            }
        }
    }

    func getPlaceholderColor() -> Color {
        return colorScheme == .dark ? darkPlaceholderColor : lightPlaceholderColor
    }

    func getTextField (placeholder: String, text: Binding<String>) -> some View {
        return TextField(placeholder,
                         text: text,
                         prompt: Text(placeholder).foregroundColor(getPlaceholderColor()))
    }
}
