//
//  ListEntryView.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/25/25.
//
import Logging
import SwiftUI

struct ListEntryView: View {
    let accountEntry: Account
    init(accountEntry: Account) {
        self.accountEntry = accountEntry
    }

    var body: some View {
        VStack {
            HStack {
                Text(accountEntry.name)
                    .font(.headline)
                Spacer()
            }.padding([.bottom], 10)
            HStack {
                Text("Username:")
                    .fontWeight(.light).font(.subheadline)
                Spacer()
                Text(accountEntry.username)
            }
            if !accountEntry.email.isEmpty {
                HStack {
                    Text("Email:").fontWeight(.light).font(.subheadline)

                    Spacer()
                    Text(accountEntry.email)
                }
            }
            HStack {
                Text("Hint:")
                    .fontWeight(.light).font(.subheadline)
                Spacer()
                Text(accountEntry.hint.isEmpty ? "(None)" : accountEntry.hint)
            }

            if !accountEntry.tags.isEmpty {
                HStack {
                    Text("Tags:")
                        .fontWeight(.light).font(.subheadline)
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
        }.padding(10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .shadow(color: Color(.blue).opacity(0.5), radius: 10, x: 5, y: 5)

    }
}
