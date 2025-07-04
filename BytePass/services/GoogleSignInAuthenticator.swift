//
//  GoogleServicesAuthenticator.swift
//
//  Taken from Google tutorial to support user login into
//  their Google account.
//

import Foundation
import GoogleSignIn

/// An observable class for authenticating via Google.
final class GoogleSignInAuthenticator: ObservableObject {
  private var authViewModel: AuthViewModel

  /// Creates an instance of this authenticator.
  /// - parameter authViewModel: The view model this authenticator will set logged in status on.
  init(authViewModel: AuthViewModel) {
    self.authViewModel = authViewModel
  }

  /// Signs in the user based upon the selected account.'
  /// - note: Successful calls to this will set the `authViewModel`'s `state` property.
  func signIn() {
#if os(iOS)
      //guard let rootViewController = UIWindowScene.windows.first?.rootViewController else {
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("There is no root view controller!")
      return
    }
    //let manualNonce = UUID().uuidString

      GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/drive.appdata"]){
//    GIDSignIn.sharedInstance.signIn(
//      withPresenting: rootViewController,
 //     hint: nil,
 //     additionalScopes: nil,
  //    nonce: manualNonce
    //){
      signInResult, error in
      guard let signInResult = signInResult else {
        print("Error! \(String(describing: error))")
        return
      }

      // Per OpenID Connect Core section 3.1.3.7, rule #11, compare returned nonce to manual
      //guard let idToken = signInResult.user.idToken?.tokenString,
      //      let returnedNonce = self.decodeNonce(fromJWT: idToken),
      //      returnedNonce == manualNonce else {
        // Assert a failure for convenience so that integration tests with this sample app fail upon
        // `nonce` mismatch
        //assertionFailure("ERROR: Returned nonce doesn't match manual nonce!")
        //return
      //}
      self.authViewModel.state = .signedIn(signInResult.user)
    }

#elseif os(macOS)
    guard let presentingWindow = NSApplication.shared.windows.first else {
      print("There is no presenting window!")
      return
    }

    GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) { signInResult, error in
      guard let signInResult = signInResult else {
        print("Error! \(String(describing: error))")
        return
      }
      self.authViewModel.state = .signedIn(signInResult.user)
    }
#endif
  }

  /// Signs out the current user.
  func signOut() {
    GIDSignIn.sharedInstance.signOut()
    authViewModel.state = .signedOut
  }

  /// Disconnects the previously granted scope and signs the user out.
  func disconnect() {
    GIDSignIn.sharedInstance.disconnect { error in
      if let error = error {
        print("Encountered error disconnecting scope: \(error).")
      }
      self.signOut()
    }
  }

  /// Adds the drive scope for the current user.
  /// - parameter completion: An escaping closure that is called upon successful completion of the
  /// `addScopes(_:presenting:)` request.
  /// - note: Successful requests will update the `authViewModel.state` with a new current user that
  /// has the granted scope.
  func addDriveScope(completion: @escaping () -> Void) {
    guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
      fatalError("No user signed in!")
    }
    
    #if os(iOS)
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      fatalError("No root view controller!")
    }

    currentUser.addScopes(["https://www.googleapis.com/auth/drive.appdata"],
                          presenting: rootViewController) { signInResult, error in
      if let error = error {
        print("Found error while adding scope: \(error).")
        return
      }

      guard let signInResult = signInResult else { return }
      self.authViewModel.state = .signedIn(signInResult.user)
      completion()
    }

    #elseif os(macOS)
    guard let presentingWindow = NSApplication.shared.windows.first else {
      fatalError("No presenting window!")
    }

    currentUser.addScopes(["https://www.googleapis.com/auth/drive.appdata"],
                          presenting: presentingWindow) { signInResult, error in
      if let error = error {
        print("Found error while adding scope: \(error).")
        return
      }

      guard let signInResult = signInResult else { return }
      self.authViewModel.state = .signedIn(signInResult.user)
      completion()
    }

    #endif
  }

}

// MARK: Parse nonce from JWT ID Token

private extension GoogleSignInAuthenticator {
    func decodeNonce(fromJWT jwt: String) -> String? {
        let segments = jwt.components(separatedBy: ".")
        guard let parts = decodeJWTSegment(segments[1]),
              let nonce = parts["nonce"] as? String else {
            return nil
        }
        return nonce
    }
    
    func decodeJWTSegment(_ segment: String) -> [String: Any]? {
        guard let segmentData = base64UrlDecode(segment),
              let segmentJSON = try? JSONSerialization.jsonObject(with: segmentData, options: []),
              let payload = segmentJSON as? [String: Any] else {
            return nil
        }
        return payload
    }
    
    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
}
