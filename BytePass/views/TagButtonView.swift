//
//  TagButtonView.swift
//
//  This is the content view of the buttons shown in Search View
//  which is basically our landing/home page. Each button is associated
//  with a tag value and the action takes you to a results view showing all
//  entries containing the associated tag.
//
import SwiftUI

struct TagButtonView: View {
    let buttonText: String
    var itemCount: String

    init(
        text: String,
        itemCount: String = "0"
    ) {
        self.buttonText = text
        self.itemCount = itemCount
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: getImageName(from: buttonText))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25, alignment: .topLeading)
                    .foregroundColor(.blue)
                    .padding([.top, .leading], 0)
                Spacer()
                Text(itemCount).padding(.bottom).padding([.top, .trailing], 0)
            }.padding(0)
            HStack {
                Text(buttonText)
                    .font(.headline)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text("->").padding(0).font(.footnote)

            }.padding([.leading, .bottom, .trailing], 0)
        }
        .padding(10)
        //.foregroundColor(textColor)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        //.scaleEffect(tapped ? 1.2 : 1)
        //.shadow(color: Color(.blue).opacity(0.5), radius: 10, x: 5, y: 5)
        //.animation(.spring(response: 0.4, dampingFraction: 0.6))
        .shadow(color: Color(.blue).opacity(0.5), radius: 10, x: 5, y: 5)
        //.frame(maxWidth: .infinity)
        //.frame(minWidth: 140)
        //.fixedSize()
    }

    func getImageName(from: String) -> String {
        switch from {
        case "bank", "invest", "investment", "finance":
            return "dollarsign.bank.building"
        case "all":
            return "list.star"
        case "property", "home", "house":
            return "house"
        case "hotel", "hotels":
            return "house.lodge"
        case "music":
            return "music.quarternote.3"
        case "medical", "hospital", "doctor":
            return "cross"
        case "travel", "airline":
            return "airplane.departure"
        case "health", "fitness":
            return "heart"
        case "shopping", "shop", "retail":
            return "dollarsign"
        case "food", "eat", "restaurant", "restaurants":
            return "fork.knife.circle"
        case "insurance":
            return "shield"
        case "ai":
            return "brain"
        case "develop":
            return "laptopcomputer"
        case "entertainment", "streaming":
            return "play.tv"
        case "wifi", "internet":
            return "wifi"
        default:
            var toReturn = String(from.first ?? "x")
            toReturn += ".circle"
            return toReturn
        }
    }
}
