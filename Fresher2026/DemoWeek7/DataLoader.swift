//
//  DataLoader.swift
//  Fresher2026   ← APP target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 2 — a GCD completion-handler API (simulated, no network) for async-testing practice.
//

import Foundation

struct DataLoader {

    enum LoaderError: Error { case failed }

    /// Delivers a result asynchronously via a completion handler (classic GCD style).
    /// `shouldSucceed` lets tests drive both the success and failure paths deterministically.
    func load(shouldSucceed: Bool = true,
              completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
            if shouldSucceed {
                completion(.success("data"))
            } else {
                completion(.failure(LoaderError.failed))
            }
        }
    }
}
