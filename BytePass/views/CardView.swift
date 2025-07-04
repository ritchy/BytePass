//
//  CardView.swift
//
//  This view isn't currently used, but leveraged for future reference
//  for potential a Button content view or in a grid layout.
//
import SwiftUI

struct CardView: View {
    var themeColor: Color = .blue
    var textColor: Color = .black

    init(themeColor: Color = .blue, textColor: Color = .black) {
        self.themeColor = themeColor
        self.textColor = textColor
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text("Account Details")
                .font(.headline)
            Spacer()
            HStack {
                Label("\(3)", systemImage: "person.3")
                Spacer()
                Label("\(15)", systemImage: "clock")
                    .labelStyle(.trailingIcon)
            }
            .font(.caption)
        }
        .padding()
        .foregroundColor(textColor)
        .background(themeColor.opacity(0.2))
        //.fixedSize()
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}


extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: Self { Self() }
}
