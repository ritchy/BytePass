import GoogleSignIn
import Logging
//
//  AuthViewModel.swift
//  BytePass
//
//  Created by Robert Ritchy on 5/14/25.
import SwiftUI

/// A class conforming to `ObservableObject` used to represent a user's authentication status.
final class AuthViewModel: ObservableObject {
    /// The user's log in status.
    /// - note: This will publish updates when its value changes.
    @Published var state: State
    let log = Logger(label: "io.bytestream.bytepass.AuthViewModel")
    private var authenticator: GoogleSignInAuthenticator {
        return GoogleSignInAuthenticator(authViewModel: self)
    }
    /// The user-authorized scopes.
    /// - note: If the user is logged out, then this will default to empty.
    var authorizedScopes: [String] {
        switch state {
        case .signedIn(let user):
            print("signed in with scopes: \(user.grantedScopes ?? [])")
            return user.grantedScopes ?? []
        case .signedOut:
            return []
        }
    }

    /// Creates an instance of this view model.
    init() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.state = .signedIn(user)
        } else {
            self.state = .signedOut
        }
    }

    /// Signs the user in.
    func signIn() {
        authenticator.signIn()
    }

    /// Signs the user out.
    func signOut() {
        log.info("signing out ...")
        authenticator.signOut()
    }

    /// Disconnects the previously granted scope and logs the user out.
    func disconnect() {
        authenticator.disconnect()
    }
}

extension AuthViewModel {
    /// An enumeration representing logged in status.
    enum State {
        /// The user is logged in and is the associated value of this case.
        case signedIn(GIDGoogleUser)
        /// The user is logged out.
        case signedOut
    }
}
