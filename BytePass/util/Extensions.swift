//
//  Extensions.swift
//  BytePass
//
//  Created by Robert Ritchy on 6/22/25.
//
import SwiftUI

// hide the keyboard - doesn't work yet
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

extension Date {
    func currentTimeInMillis() -> Int64 {
        let currentTimeInMillis = Int64(
            //seconds since 1970 times 1000
            NSDate().timeIntervalSince1970 * 1000
        )
        return currentTimeInMillis
    }
}
