//
//  TagButtonView.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/24/25.
//

//
//  CardView.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/4/25.
//
import SwiftUI

struct TagButtonView: View {
    let buttonText: String
    var themeColor: Color = .blue
    var textColor: Color = .black

    init(text: String, themeColor: Color = .blue, textColor: Color = .black) {
        self.buttonText = text
        self.themeColor = themeColor
        self.textColor = textColor
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
                Text("3").padding(.bottom).padding([.top, .trailing], 0)
            }.padding(0)
            HStack {
                //Spacer()
                //Label("\(3)", systemImage: getImageName(from: buttonText)).frame(width: 40, height: 40, alignment: .center)
                Text(buttonText)
                    .font(.headline)
                Spacer()
                //Text(">").padding([.trailing], 0)

            }.padding(.bottom, 0)
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
        case "hotel":
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
        default:
            var toReturn = String(from.first ?? "x")
            toReturn += ".circle"
            return toReturn
        }
    }
}
