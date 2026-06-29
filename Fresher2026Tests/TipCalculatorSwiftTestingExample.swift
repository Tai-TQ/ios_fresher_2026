//
//  TipCalculatorSwiftTestingExample.swift
//  Fresher2026Tests   ← UNIT TEST target (Xcode 16+)
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 6 (OPTIONAL) — the Module 1 TipCalculator, tested with Swift Testing.
//  Comments show the XCTest equivalent. Requires `import Testing` (Xcode 16+).
//  Swift Testing and XCTest can live in the same target.
//

import Testing
@testable import Fresher2026

@Suite struct TipCalculatorSwiftTestingExample {

    // A fresh suite instance is created per test → this acts like setUp(), no boilerplate.
    let sut = TipCalculator()

    @Test("Tip is 20% of the bill")
    func tipForTwentyPercent() {
        #expect(sut.tip(forBill: 100, percentage: 20) == 20)
        // XCTest equivalent:
        // XCTAssertEqual(sut.tip(forBill: 100, percentage: 20), 20, accuracy: 0.001)
    }

    @Test("Total equals bill plus tip")
    func totalEqualsBillPlusTip() {
        #expect(sut.total(forBill: 50, percentage: 10) == 55)
    }

    // Parameterized: each case is run and reported separately — no loop, no duplication.
    @Test("Tip across several bills", arguments: [
        (bill: 100.0, percent: 20.0, expected: 20.0),
        (bill: 50.0,  percent: 10.0, expected: 5.0),
        (bill: 0.0,   percent: 20.0, expected: 0.0),
    ])
    func tip(bill: Double, percent: Double, expected: Double) {
        #expect(sut.tip(forBill: bill, percentage: percent) == expected)
    }
}
