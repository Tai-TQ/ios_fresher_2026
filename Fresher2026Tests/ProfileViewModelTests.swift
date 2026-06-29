//
//  ProfileViewModelTests.swift
//  Fresher2026Tests   ← UNIT TEST target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 3 — hand-written test doubles (Stub + Spy) and testing without the network.
//

import XCTest
@testable import Fresher2026

// MARK: - Test doubles (hand-written, no library needed)

/// STUB — returns whatever canned result the test sets, synchronously.
final class UserProvidingStub: UserProviding {
    var result: Result<User, Error>
    init(result: Result<User, Error>) { self.result = result }

    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
        completion(result)
    }
}

/// SPY — a stub that also records how it was called.
final class UserProvidingSpy: UserProviding {
    private(set) var fetchCallCount = 0
    private(set) var lastRequestedID: Int?
    var stubbedResult: Result<User, Error> = .success(User(id: 0, name: "Stub"))

    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
        fetchCallCount += 1
        lastRequestedID = id
        completion(stubbedResult)
    }
}

// MARK: - Tests

final class ProfileViewModelTests: XCTestCase {
    
    func test_smoke() {
        XCTAssertTrue(true)
    }

    func test_loadGreeting_givenSuccess_setsGreetingWithName() {
        // The stub completes synchronously → no XCTestExpectation needed.
        let stub = UserProvidingStub(result: .success(User(id: 1, name: "Tai")))
        let sut = ProfileViewModel(provider: stub)

        sut.loadGreeting(userID: 1)

        XCTAssertEqual(sut.greeting, "Hello, Tai!")
    }

//    func test_loadGreeting_givenFailure_setsFallbackGreeting() {
//        let stub = UserProvidingStub(result: .failure(NSError(domain: "test", code: 0)))
//        let sut = ProfileViewModel(provider: stub)
//
//        sut.loadGreeting(userID: 1)
//
//        XCTAssertEqual(sut.greeting, "Welcome!")
//    }

    func test_loadGreeting_requestsTheCorrectUserID() {
        // SPY verifies the interaction itself.
        let spy = UserProvidingSpy()
        let sut = ProfileViewModel(provider: spy)

        sut.loadGreeting(userID: 42)

        XCTAssertEqual(spy.fetchCallCount, 1)
        XCTAssertEqual(spy.lastRequestedID, 42)
    }
}
