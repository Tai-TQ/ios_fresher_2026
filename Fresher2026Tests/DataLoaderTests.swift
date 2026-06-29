//
//  DataLoaderTests.swift
//  Fresher2026Tests   ← UNIT TEST target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 2 — testing asynchronous (GCD completion-handler) code with XCTestExpectation.
//

import XCTest
@testable import Fresher2026

final class DataLoaderTests: XCTestCase {

    private var sut: DataLoader!

    override func setUp() {
        super.setUp()
        sut = DataLoader()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_load_givenSuccess_deliversData() {
        let expectation = expectation(description: "loader completes")

        sut.load(shouldSucceed: true) { result in
            switch result {
            case .success(let value): XCTAssertEqual(value, "data")
            case .failure: XCTFail("expected success, got failure")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_load_givenFailure_deliversError() {
        let expectation = expectation(description: "loader completes")

        sut.load(shouldSucceed: false) { result in
            if case .success = result { XCTFail("expected failure, got success") }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    /// Inverted expectation: assert the completion is NOT called a second time.
    func test_load_doesNotCallCompletionTwice() {
        let expectation = expectation(description: "completion should fire exactly once")
        expectation.expectedFulfillmentCount = 2
        expectation.isInverted = true        // failing the test if it IS fulfilled twice

        sut.load { _ in expectation.fulfill() }

        wait(for: [expectation], timeout: 0.5)
    }
}
