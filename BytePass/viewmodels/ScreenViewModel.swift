//
//  ScreenViewModel.swift
//  BytePass
//
//  Created by Robert Ritchy on 9/3/25.
//

import SwiftUI

class ScreenViewModel: ObservableObject {
    public static let SearchView: String = "SearchView"
    public static let SyncingScreen: String = "SyncingScreen"
    public static let SignOutScreen: String = "SignOutScreen"
    public static let ResultsView: String = "ResultsView"
    public static let SearchingScreen: String = "SearchingScreen"
    public static let NewAccountView: String = "NewAccountView"
    @Published var currentView: String
    @Published public var showingNewAccountScreen: Bool = false
    @Published public var showingResultsScreen: Bool = false

    init(currentView: String = SearchView) {
        self.currentView = currentView
    }
    
    func updateCurrentView(_ newView: String) {
        self.currentView = newView
    }
}
