//
//  NumberCruncherPerformanceTests.swift
//  Fresher2026Tests   ← UNIT TEST target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 5 — performance tests with measure { } and measure(metrics:).
//  After the first run, set a Baseline (gray diamond → Set Baseline) to catch regressions.
//

import XCTest
@testable import Fresher2026

final class NumberCruncherPerformanceTests: XCTestCase {

    private var sut: NumberCruncher!

    override func setUp() {
        super.setUp()
        sut = NumberCruncher()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_performance_bubbleSort() {
        // Build the data OUTSIDE measure so we time only the sort, not the setup.
        let input = (0..<2_000).map { _ in Int.random(in: 0...10_000) }

        measure {
            _ = sut.bubbleSort(input)
        }
    }

    func test_performance_bubbleSort_clockMemoryCPU() {
        let input = (0..<2_000).map { _ in Int.random(in: 0...10_000) }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            _ = sut.bubbleSort(input)
        }
    }

    func test_performance_sumOfPrimes() {
        measure {
            _ = sut.sumOfPrimes(below: 50_000)
        }
    }
}
