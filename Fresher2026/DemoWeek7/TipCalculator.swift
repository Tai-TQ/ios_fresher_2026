//
//  TipCalculator.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 1 — a tiny, pure system-under-test (no UIKit) so tests are trivial to reason about.
//

import Foundation

struct TipCalculator {

    /// The tip amount for a bill at a given percentage.
    func tip(forBill bill: Double, percentage: Double) -> Double {
        bill * percentage / 100
    }

    /// The bill plus the tip.
    func total(forBill bill: Double, percentage: Double) -> Double {
        bill + tip(forBill: bill, percentage: percentage)
    }
}
