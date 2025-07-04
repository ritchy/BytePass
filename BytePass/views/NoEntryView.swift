//
//  NoEntryView.swift
//  BytePass
//
//  Shown when there are zero account entries, typically first time use.
//
import SwiftUI

struct NoEntryView: View {
    var body: some View {
        VStack(alignment: .center) {
                HStack(alignment: .center) {
                    Image(systemName: "plus.app")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40, alignment: .topLeading)
                        .foregroundColor(.blue)
                        //.padding([.top, .leading], 0)
                }.padding([.bottom], 20)
                HStack(alignment: .center) {
                    Text("no entries, tap here to add one!")
                        .font(.headline)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .shadow(color: Color(.blue).opacity(0.5), radius: 10, x: 5, y: 5)
    }

}
