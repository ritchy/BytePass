//
//  TagEditorView.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/19/25
//

import SwiftUI
import Logging

struct TagEditorView: View {

    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedAccount: Account
    @StateObject var viewModel: TagEditorViewModel

    let log = Logger(label: "com.jarbo.bytepass.TagEditorView")

    func getViewModel() -> TagEditorViewModel {
        return viewModel
    }

    var body: some View {
        VStack(alignment: .center) {
            Text("Manage Tags")
                .padding()
            ScrollView {
                TagListView(viewModel: viewModel).padding()
                Spacer()
            }
            EditableDropdown(viewModel: viewModel) //, selectedAccount: $selectedAccount)
            //.background(Color.green)
        }
    }
}

/**
 View to show circular representation of tags with an 'x' buton to delete the tag from the group.
 The grouping maximizes the number of tags per row.
 */
struct TagListView: View {
    @StateObject var viewModel: TagEditorViewModel

    init(viewModel: TagEditorViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.rows, id: \.self) { rows in
                    HStack(spacing: 6) {
                        ForEach(rows) { row in
                            Text(row.name)
                                .font(.system(size: 16))
                                .padding(.leading, 14)
                                .padding(.trailing, 30)
                                .padding(.vertical, 8)
                                .background(
                                    ZStack(alignment: .trailing) {
                                        Capsule()
                                            .fill(.blue.opacity(0.3))
                                        Button {
                                            viewModel.removeTagById(
                                                by: row.id
                                            )
                                            viewModel.removeSelectedTag(by: row.name)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .padding(10)
                                                .foregroundColor(.blue)
                                                .cornerRadius(10)
                                                .imageScale(.small)
                                            //.frame(width: 6, height: 6)
                                        }
                                    }
                                )
                        }
                    }
                    .frame(height: 28)
                    .padding(.bottom, 10)
                }
            }
            .padding(24)
        }
    }
}


struct EditableDropdown: View {
    @State private var allTags: [String]
    @StateObject var viewModel: TagEditorViewModel
    //@Binding var selectedAccount: Account

    let log = Logger(label: "io.bytestream.bytepass.EditableDropdown")

    init(viewModel: TagEditorViewModel) {
        //}, selectedAccount: Binding<Account>) {
        _viewModel = .init(wrappedValue: viewModel)
        self.allTags = viewModel.getTagsAsStringArray()
        //_selectedAccount = selectedAccount
    }

    func clear() {
        log.info ("clearing ...")
        viewModel.tagText = ""
    }

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                //Form {
                TextField(
                    "Add a Tag",
                    text: $viewModel.tagText,
                ).onSubmit {
                    viewModel.addTextTag(tagText: viewModel.tagText)
                    log.info ("committing -> \(viewModel.selectedTags) - tag text: \(viewModel.tagText)")
                    //selectedAccount.tags = viewModel.selectedTags
                    allTags = viewModel.getTagsAsStringArray()
                }
                //.textFieldStyle(PlainTextFieldStyle()).padding().background(Color.secondary.opacity(0.2))
                .textFieldStyle(RoundedBorderTextFieldStyle()).padding().background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder()
                        .foregroundColor(.black)
                ).padding([.top, .leading, .trailing], 18)
                .textInputAutocapitalization(.never)
                //.padding()
                //t.clearsOnBeginEditing(true)
                if #available(iOS 17.0, *) {
                    if !viewModel.tagText.isEmpty {
                        List {
                            ForEach(
                                allTags.filter {
                                    viewModel.tagText.isEmpty
                                        || $0.localizedCaseInsensitiveContains(
                                            viewModel.tagText
                                        )
                                },
                                id: \.self
                            ) { option in
                                Text(option)
                                    .onTapGesture {
                                        viewModel.addTextTag(tagText: option)
                                        viewModel.tagText = ""
                                    }
                            }
                        }//.padding([.bottom, .trailing])
                            //.background(Color.blue)
                            .contentMargins(.top, 0)
                            .frame(maxHeight: 124)
                            .scrollContentBackground(.hidden)
                    } else {
                        VStack {
                        }.padding([.bottom, .trailing])
                            //.background(Color.blue)
                            .contentMargins(.top, 0)
                            .frame(maxHeight: 124)

                    }
                } else {
                    // Fallback on earlier versions
                }
                /**
                }.onSubmit {
                    print("on submit")
                    viewModel.tagText = ""
                }.padding(0)
                    .background(Color.blue)
                    .lineSpacing(0)
                 **/
            }//.background(Color.yellow)
        }.padding()
            //.background(Color.green)
    }
}

/***
 @State var showDropDown: Bool = false

struct MyDropDown: View {

    let origTags = ["one", "two", "three", "four", "five", "six", "seven"]
    @State var tags = ["one", "two", "three"]

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                //List{
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                    }) {
                        Text(tag)
                            //.fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 9)
                            .frame(maxWidth: .infinity)
                            .background(.blue.opacity(0.6))
                            .cornerRadius(14)
                    }.fixedSize()
                }
                //}.background(Color.blue.opacity(0.8))
            }
            .background(Color.clear)  //(Color.white.opacity(0.5))
            .padding([.trailing], 100)
            .padding([.bottom], 20)
            //Spacer()
        }  //.frame(height: 28)
        //.offset(x: 5, y: -20)
        //.padding([.bottom, .leading, .trailing])
        //.padding([.leading, .trailing], 50)
        //.background(Color.blue)
        .background(Color.blue.opacity(0.9))
        //.border(Color.black, width: 0.25)
        //.overlay(
        //       RoundedRectangle(cornerRadius: 16)
        //          .stroke(.blue, lineWidth: 4)
        // )
    }
}

public struct DropDownView: View {
    @Binding var selectedText: String
    @State var dropDownList = [
        "one", "two", "three", "four", "five", "six", "seven",
    ]
    @State var showDropDown = false
    @State var rowColor: Color = Color.primary
    @State var outlineColor: Color = Color.secondary
    @State var selectedTextColor: Color = Color.secondary
    @State var label: String = "Enter"
    @State var placeHolder: String = "placholder"
    @State var showLabel = false
    public init(
        selectedText: Binding<String>,
        dropDownList: [String],
        rowColor: Color = .white,
        outlineColor: Color = .black,
        selectedTextColor: Color = .black,
        label: String = "",
        showLabel: Bool = false,
        placeHoder: String = ""
    ) {
        self._selectedText = selectedText
        self._dropDownList = State(initialValue: dropDownList)
        self._rowColor = State(initialValue: rowColor)
        self._outlineColor = State(initialValue: outlineColor)
        self._selectedTextColor = State(initialValue: selectedTextColor)
        self._label = State(initialValue: label)
        self._placeHolder = State(initialValue: placeHoder)
    }
    public var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.black)
                //.hiddenConditionally(isHidden: $showLabel)
                HStack {
                    TextField(placeHolder, text: $selectedText)
                        .padding([.horizontal, .vertical], 15)
                        .font(.caption)
                        .foregroundColor(selectedTextColor)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showDropDown.toggle()
                            }
                        }
                        .onChange(of: selectedText) { newValue in
                            showDropDown = false
                        }
                    Image(
                        systemName: showDropDown
                            ? "chevron.down" : "chevron.right"
                    )
                    .padding()
                }.overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 0.5)
                ).foregroundColor(outlineColor)
            }
            //if showDropDown {
            ScrollView(showsIndicators: false) {
                ForEach(dropDownList, id: \.self) { number in
                    VStack(alignment: .leading) {
                        Text("\(number)")
                            .padding(.horizontal)
                            .font(.caption)
                        Divider()
                    }
                    .background(rowColor.opacity(0.4))
                    .onTapGesture {
                        selectedText = "\(number)"
                        showDropDown.toggle()
                    }
                }
            }
            //.hiddenConditionally(isHidden: $showDropDown)
            //}
        }.onAppear {
            showLabel = !label.isEmpty
        }
    }
}

****/

/***
 //ZStack(alignment: .topLeading) {
//     EditableDropdown(viewModel: viewModel)//.background(Color.green)
     //DropDownView(selectedText: $viewModel.tagText, dropDownList: ["one", "two", "three", "four", "five", "six", "seven"])
//     Spacer()
 //}
 //.background(Color.clear)  //Color.yellow.opacity(0.7))
 //Spacer()
TextField(
    "Enter tag",
    text: $viewModel.tagText,
    onCommit: {
        viewModel.addTag()
        selectedAccount.tags = viewModel.getTagsAsStringArray()
        showDropDown = false
        //viewModel.tagText = "--"
    }
).onChange(of: viewModel.tagText) { newValue in
    tags = origTags
    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty
    {
        tags = tags.filter({
            $0.lowercased().contains(newValue.lowercased())
        })
        showDropDown = true
    } else {
        showDropDown = false
    }
}.padding()
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder()
            .foregroundColor(.black)
    ).padding([.top, .leading, .trailing], 24)
***/
