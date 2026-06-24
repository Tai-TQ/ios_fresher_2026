//
//  TipCalculatorTests.swift
//  Fresher2026Tests
//
//  Created by TaiTQ2 on 24/6/26.
//

import XCTest
@testable import Fresher2026

final class TipCalculatorTests: XCTestCase {

    // A fresh system-under-test for every test keeps them Independent (the "I" in FIRST).
    private var sut: TipCalculator!

    override func setUp() {
        super.setUp()
        sut = TipCalculator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_tip_givenTwentyPercent_returnsTwentyPercentOfBill() {
        // Arrange — sut is ready from setUp()
        // Act
        let tip = sut.tip(forBill: 100, percentage: 20)
        // Assert (accuracy: floating-point compares need a tolerance)
        XCTAssertEqual(tip, 20, accuracy: 0.001)
    }

    func test_total_givenTenPercent_returnsBillPlusTip() {
        let total = sut.total(forBill: 50, percentage: 10)
        XCTAssertEqual(total, 55, accuracy: 0.001)
    }

    // 🐞 Lab 3: uncomment to see a RED failure and read its message in the editor gutter.
    // func test_tip_intentionalFailure() {
    //     let tip = sut.tip(forBill: 100, percentage: 20)
    //     XCTAssertEqual(tip, 25, accuracy: 0.001)   // wrong on purpose — expected 20
    // }
}
