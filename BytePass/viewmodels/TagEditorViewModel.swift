//
//  TagEditorViewModel.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/15/25.
//
import SwiftUI
import Logging

class TagEditorViewModel: ObservableObject {

    @Published var allTags: [String] = []
    @Published var selectedTags: [String]
    @Published var rows: [[Tag]] = []
    @Published var tags: [Tag] = []
    @Published var tagText = ""
    @Binding var selectedAccount: Account

    let log = Logger(label: "io.bytestream.bytepass.TagEditorViewModel")

    init(selectedTags: [String], allTags: [String], selectedAccount: Binding<Account>) {
        _selectedTags = .init(wrappedValue: selectedTags)
        _allTags = .init(wrappedValue: allTags)
        _selectedAccount = selectedAccount
        selectedTags.forEach { tag in
            tags.append(Tag(name: tag))
        }
        getTags()
    }

    func addTag() {
        tags.append(Tag(name: tagText.lowercased()))
        tagText = ""
        getTags()
    }
    
    func addTextTag(tagText: String) {
        let toAdd = tagText.lowercased()
        if (!selectedTags.contains(toAdd)) {
            tags.append(Tag(name: toAdd))
            allTags.append(toAdd)
            selectedTags.append(toAdd)
            selectedAccount.tags = selectedTags
        } else {
            log.info ("tag \(toAdd) already exists")
        }
        self.tagText = ""
        getTags()
    }
    
    func removeSelectedTag(by name: String) {
        selectedTags.removeAll() {
            $0 == name
        }
        selectedAccount.tags = selectedTags
        log.info ("selected tags after removal \(selectedTags)")
    }

    func removeTagById (by id: String) {
        tags = tags.filter { $0.id != id }
        getTags()
    }

    func getTagsAsStringArray() -> [String] {
        return allTags
    }

    func getTags() {
        var rows: [[Tag]] = []
        var currentRow: [Tag] = []

        var totalWidth: CGFloat = 0

        let screenWidth = UIScreen.screenWidth - 10
        let tagSpaceing: CGFloat = 56

        if !tags.isEmpty {

            for index in 0..<tags.count {
                self.tags[index].size = tags[index].name.getSize()
            }

            tags.forEach { tag in

                totalWidth += (tag.size + tagSpaceing)

                if totalWidth > screenWidth {
                    totalWidth = (tag.size + tagSpaceing)
                    rows.append(currentRow)
                    currentRow.removeAll()
                    currentRow.append(tag)
                } else {
                    currentRow.append(tag)
                }
            }

            if !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow.removeAll()
            }

            self.rows = rows
        } else {
            self.rows = []
        }

    }
}

extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.width
}

extension String {
    func getSize() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (self as NSString).size(withAttributes: attributes)
        return size.width
    }
}

struct Tag: Identifiable, Hashable {
    var id = UUID().uuidString
    var name: String
    var size: CGFloat = 0
}

