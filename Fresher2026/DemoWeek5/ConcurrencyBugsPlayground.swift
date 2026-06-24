//
//  ConcurrencyBugsPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//  Module 6 — Diagnosing & Fixing Concurrency Bugs.
//

import UIKit

final class ConcurrencyBugsPlayground: UIViewController {

    // MARK: - State

    private var unsafeCounter = 0                    // intentionally unguarded (data race)

    private var safeCounter = 0
    private let counterLock = NSLock()               // guards safeCounter

    // For the check-then-act demo: a thread-safe store + a guarded call counter,
    // so the ONLY bug is the logic race (no data race for TSan to find).
    private let storeQueue = DispatchQueue(label: "com.fresher2026.store")
    private var store: [String: Int] = [:]
    private var expensiveCallCount = 0
    private let expensiveLock = NSLock()

    private let logQueue = DispatchQueue(label: "com.fresher2026.bugs.log")
    private var logBuffer = ""
    private let startTime = Date()

    // MARK: - Views

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Concurrency Bugs"
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(makeButton("Counter: UNSAFE (data race)", "exclamationmark.triangle") { [weak self] in self?.runUnsafe() })
        buttonStack.addArrangedSubview(makeButton("Counter: SAFE (NSLock)", "checkmark.shield") { [weak self] in self?.runSafe() })
        buttonStack.addArrangedSubview(makeButton("Check-then-act (logic race)", "questionmark.diamond") { [weak self] in self?.runCheckThenAct() })
        buttonStack.addArrangedSubview(makeButton("Clear log", "trash") { [weak self] in self?.clearLog() })

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.45),

            buttonStack.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - 1. Unsafe counter (DATA RACE — TSan flags this)

    private func runUnsafe() {
        section("Counter: UNSAFE — expect a wrong total + a TSan report")
        unsafeCounter = 0
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                self.unsafeCounter += 1                 // 💥 data race: concurrent read-modify-write
            }
            self.log("UNSAFE total = \(self.unsafeCounter)  (expected 10000)")
        }
    }

    // MARK: - 2. Safe counter (NSLock — correct, TSan silent)

    private func runSafe() {
        section("Counter: SAFE — NSLock makes the increment atomic")
        safeCounter = 0
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                self.counterLock.lock()
                self.safeCounter += 1
                self.counterLock.unlock()
            }
            self.log("SAFE total = \(self.safeCounter)  (expected 10000)")
        }
    }

    // MARK: - 3. Check-then-act (LOGIC RACE — TSan does NOT catch this)

    private func runCheckThenAct() {
        section("Check-then-act — thread-safe store, still does the work twice")
        storeQueue.sync { store["key"] = nil }
        expensiveLock.lock(); expensiveCallCount = 0; expensiveLock.unlock()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            DispatchQueue.concurrentPerform(iterations: 8) { _ in
                // CHECK (thread-safe read)
                let alreadyDone = self.storeQueue.sync { self.store["key"] != nil }
                if !alreadyDone {
                    // ACT — but several threads may have passed the check together
                    let value = self.computeExpensive()
                    self.storeQueue.sync { self.store["key"] = value }
                }
            }
            let count = self.expensiveLock.performLocked { self.expensiveCallCount }
            self.log("expensive() ran \(count) time(s)  (should be 1) — logic race, no data race")
        }
    }

    private func computeExpensive() -> Int {
        expensiveLock.lock()
        expensiveCallCount += 1
        expensiveLock.unlock()
        Thread.sleep(forTimeInterval: 0.05)      // widen the race window
        return 42
    }

    // 🐞 BUG (Lab 4): lock-ordering deadlock. Two threads take two locks in opposite
    //     orders, so each ends up waiting on the other forever. Uncomment, wire to a
    //     button, run, and watch the app hang; pause in Xcode to see both threads
    //     stuck. Fix = always acquire locks in the SAME order everywhere. Re-comment after.
    //
    // private let lockA = NSLock()
    // private let lockB = NSLock()
    // private func runLockOrderingDeadlock() {
    //     section("Lock-ordering DEADLOCK (will hang the app)")
    //     DispatchQueue.global().async {
    //         self.lockA.lock(); self.log("t1: holds A, wants B")
    //         Thread.sleep(forTimeInterval: 0.1)
    //         self.lockB.lock()                    // waits for t2 forever
    //         self.lockB.unlock(); self.lockA.unlock()
    //     }
    //     DispatchQueue.global().async {
    //         self.lockB.lock(); self.log("t2: holds B, wants A")
    //         Thread.sleep(forTimeInterval: 0.1)
    //         self.lockA.lock()                    // waits for t1 forever → deadlock
    //         self.lockA.unlock(); self.lockB.unlock()
    //     }
    // }

    // MARK: - Logging

    private func log(_ message: String) {
        let stamp = String(format: "%6.3fs", Date().timeIntervalSince(startTime))
        logQueue.async {
            self.logBuffer += "[\(stamp)]  \(message)\n"
            self.render()
        }
    }

    private func section(_ title: String) {
        logQueue.async {
            if !self.logBuffer.isEmpty { self.logBuffer += "\n" }
            self.logBuffer += "=== \(title) ===\n"
            self.render()
        }
    }

    private func clearLog() {
        logQueue.async {
            self.logBuffer = ""
            self.render()
        }
    }

    private func render() {
        let snapshot = logBuffer
        DispatchQueue.main.async {
            self.textView.text = snapshot
            self.textView.scrollRangeToVisible(NSRange(location: (snapshot as NSString).length, length: 0))
        }
    }

    // MARK: - Helpers

    private func makeButton(_ title: String, _ symbol: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 8
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}

private extension NSLock {
    /// Small convenience: run a closure while holding the lock.
    func performLocked<T>(_ body: () -> T) -> T {
        lock(); defer { unlock() }
        return body()
    }
}
