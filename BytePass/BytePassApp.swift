//
//  BytePassApp.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/19/25.
//

import Combine
import GoogleSignIn
import Logging
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        return true
    }
}

@main
struct BytePassApp: App {
    var dataManager = DataManager()
    var googleService: GoogleService?
    //@StateObject var googleService = GoogleService(dataManager: DataManager())
    @StateObject var authViewModel = AuthViewModel()

    let log = Logger(label: "io.bytestream.bytepass.BytePassApp")

    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        //print("initialized app delegate...")
        googleService = GoogleService (dataManager:dataManager)
        // Configure app settings
        setupAppSettings()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SearchView()
                    //LoadJSONView()
                    .environmentObject(dataManager)
                    .environmentObject(googleService!)
                    .environmentObject(authViewModel)
            }
            .onAppear {
                // Check and create necessary directories on app launch
                ensureAppDirectories()
            }
        }
    }

    private func setupAppSettings() {
        // Print the app's document directory path for debugging
        if let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            print("Documents Directory: \(documentsDirectory.path)")
        }

    }

    private func ensureAppDirectories() {
        guard
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            print("Could not access documents directory")
            return
        }

        let dataDirectory = documentsDirectory.appendingPathComponent(
            "BytePassData",
            isDirectory: true
        )

        if !FileManager.default.fileExists(atPath: dataDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true
                )
                print(
                    "Created BytePassData directory at: \(dataDirectory.path)"
                )
            } catch {
                print(
                    "Error creating BytePassData directory: \(error.localizedDescription)"
                )
            }
        }
    }
}

// hide the keyboard - doesn't work yet
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
