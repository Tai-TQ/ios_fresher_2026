//
//  NumberCruncher.swift
//  Fresher2026   ← APP target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 5 — deliberately heavy work so performance numbers are meaningful and stable.
//

import Foundation

struct NumberCruncher {

    /// Intentionally O(n²) so it's slow enough to measure (don't ship this — use `sorted()`).
    func bubbleSort(_ input: [Int]) -> [Int] {
        var array = input
        guard array.count > 1 else { return array }
        for i in 0..<(array.count - 1) {
            for j in 0..<(array.count - 1 - i) where array[j] > array[j + 1] {
                array.swapAt(j, j + 1)
            }
        }
        return array
    }

    /// A CPU-bound helper: sum of primes below `n` (trial division).
    func sumOfPrimes(below n: Int) -> Int {
        var sum = 0
        for candidate in 2..<max(2, n) where isPrime(candidate) {
            sum += candidate
        }
        return sum
    }

    private func isPrime(_ value: Int) -> Bool {
        guard value >= 2 else { return false }
        if value == 2 { return true }
        if value % 2 == 0 { return false }
        var divisor = 3
        while divisor * divisor <= value {
            if value % divisor == 0 { return false }
            divisor += 2
        }
        return true
    }
}
