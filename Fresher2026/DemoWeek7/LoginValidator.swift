//
//  LoginValidator.swift
//  Fresher2026   ← APP target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 2 — pure, synchronous branching logic to practise assertions & error testing.
//

import Foundation

enum LoginError: Error, Equatable {
    case emptyEmail
    case invalidEmail
    case emptyPassword
    case passwordTooShort
}

struct LoginValidator {

    static let minPasswordLength = 8

    /// Throws the first problem it finds; returns normally if the input is valid.
    func validate(email: String, password: String) throws {
        if email.isEmpty { throw LoginError.emptyEmail }
        guard email.contains("@"), email.contains(".") else { throw LoginError.invalidEmail }
        if password.isEmpty { throw LoginError.emptyPassword }
        guard password.count >= Self.minPasswordLength else { throw LoginError.passwordTooShort }
    }

    /// Convenience boolean form.
    func isValid(email: String, password: String) -> Bool {
        (try? validate(email: email, password: password)) != nil
    }
}
