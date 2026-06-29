//
//  ProfileViewModel.swift
//  Fresher2026   ← APP target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 3 — a view model whose dependency is INJECTED via a protocol, so tests can
//  substitute a double instead of hitting the real network.
//

import Foundation

struct User: Equatable {
    let id: Int
    let name: String
}

/// The seam: depend on this protocol, not on a concrete network class.
protocol UserProviding {
    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void)
}

final class ProfileViewModel {

    private let provider: UserProviding
    private(set) var greeting: String = ""

    // Constructor injection — production passes the real provider, tests pass a double.
    init(provider: UserProviding) {
        self.provider = provider
    }

    func loadGreeting(userID: Int, completion: @escaping () -> Void = {}) {
        provider.fetchUser(id: userID) { [weak self] result in
            switch result {
            case .success(let user): self?.greeting = "Hello, \(user.name)!"
            case .failure:           self?.greeting = "Welcome!"
            }
            completion()
        }
    }
}

// The REAL provider hits the network. We do NOT unit-test this directly — we test
// ProfileViewModel against a double. Shown only to make the seam concrete.
struct RemoteUserProvider: UserProviding {
    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
        // e.g. URLSession.shared.dataTask(...) — omitted; not exercised by unit tests.
        completion(.failure(NSError(domain: "not-implemented", code: -1)))
    }
}
