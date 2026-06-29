//
//  LoginValidatorTests.swift
//  Fresher2026Tests   ← UNIT TEST target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 2 — assertions, error assertions, XCTUnwrap, AAA + naming.
//

import XCTest
@testable import Fresher2026

final class LoginValidatorTests: XCTestCase {

    private var sut: LoginValidator!

    override func setUp() {
        super.setUp()
        sut = LoginValidator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Happy path

    func test_validate_givenValidInput_doesNotThrow() {
        XCTAssertNoThrow(try sut.validate(email: "zalo@vng.com.vn", password: "secret123"))
    }

    func test_isValid_givenValidInput_returnsTrue() {
        XCTAssertTrue(sut.isValid(email: "zalo@vng.com.vn", password: "secret123"))
    }

    // MARK: - Error paths (each asserts exactly one behaviour)

    func test_validate_givenEmptyEmail_throwsEmptyEmail() {
        XCTAssertThrowsError(try sut.validate(email: "", password: "secret123")) { error in
            XCTAssertEqual(error as? LoginError, .emptyEmail)
        }
    }

    func test_validate_givenEmailWithoutAtSign_throwsInvalidEmail() {
        XCTAssertThrowsError(try sut.validate(email: "tai.vng.com", password: "secret123")) { error in
            XCTAssertEqual(error as? LoginError, .invalidEmail)
        }
    }

    func test_validate_givenEmptyPassword_throwsEmptyPassword() {
        XCTAssertThrowsError(try sut.validate(email: "zalo@vng.com.vn", password: "")) { error in
            XCTAssertEqual(error as? LoginError, .emptyPassword)
        }
    }

    func test_validate_givenShortPassword_throwsPasswordTooShort() {
        XCTAssertThrowsError(try sut.validate(email: "zalo@vng.com.vn", password: "abc")) { error in
            XCTAssertEqual(error as? LoginError, .passwordTooShort)
        }
    }

    // MARK: - XCTUnwrap example

    func test_minPasswordLength_isReasonable() throws {
        // Contrived XCTUnwrap demo: unwrap an optional derived value before asserting.
        let boundary: Int? = LoginValidator.minPasswordLength
        let length = try XCTUnwrap(boundary)
        XCTAssertGreaterThanOrEqual(length, 8)
    }
}
