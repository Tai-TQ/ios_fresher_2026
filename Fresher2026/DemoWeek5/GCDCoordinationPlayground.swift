//
//  GCDCoordinationPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//

import UIKit

final class GCDCoordinationPlayground: UIViewController {

    // MARK: - State

    private let cache = SafeCache()
    private var inFlight = 0
    private let inFlightQueue = DispatchQueue(label: "com.fresher2026.inflight")   // guards inFlight

    // Serial queue that owns the log buffer (true cross-thread order).
    private let logQueue = DispatchQueue(label: "com.fresher2026.coord.log")
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
        title = "GCD — Coordination Tools"
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(makeButton("DispatchGroup: 5 → then show", "square.stack.3d.up") { [weak self] in self?.runGroup() })
        buttonStack.addArrangedSubview(makeButton("Semaphore: max 3 in flight", "gauge") { [weak self] in self?.runSemaphore() })
        buttonStack.addArrangedSubview(makeButton("Barrier cache: reads + writes", "lock.shield") { [weak self] in self?.runBarrierCache() })
        buttonStack.addArrangedSubview(makeButton("WorkItem: start then cancel", "xmark.circle") { [weak self] in self?.runCancellable() })
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

    // MARK: - 1. DispatchGroup — wait for many, then act once

    private func runGroup() {
        section("DispatchGroup: download 5, then show")
        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "com.fresher2026.results")   // guards the array
        var results: [String] = []

        for i in 1...5 {
            group.enter()
            DispatchQueue.global(qos: .utility).async { [weak self] in
                Thread.sleep(forTimeInterval: Double.random(in: 0.2...0.8))  // simulate download
                let name = "img\(i)"
                resultsQueue.sync { results.append(name) }                   // safe write, completes before leave
                self?.log("downloaded \(name)")
                group.leave()                                                // balance every enter()
            }
        }

        group.notify(queue: .main) { [weak self] in                          // once, after all 5
            self?.log("ALL done → show \(results.count) images (on main)")
        }
    }

    // MARK: - 2. DispatchSemaphore — cap concurrency at 3

    private func runSemaphore() {
        section("Semaphore: at most 3 running at once")
        let semaphore = DispatchSemaphore(value: 3)

        // The loop that calls wait() runs OFF the main thread — never block main.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            for i in 1...8 {
                semaphore.wait()                                  // blocks if 3 are in flight
                DispatchQueue.global(qos: .utility).async {
                    let n = self.changeInFlight(by: +1)
                    self.log("start \(i)  (in-flight = \(n))")
                    Thread.sleep(forTimeInterval: 0.5)
                    _ = self.changeInFlight(by: -1)
                    self.log("end   \(i)")
                    semaphore.signal()                            // free a slot
                }
            }
        }
    }

    private func changeInFlight(by delta: Int) -> Int {
        inFlightQueue.sync {
            inFlight += delta
            return inFlight
        }
    }

    // MARK: - 3. Barrier cache — concurrent reads, exclusive writes

    private func runBarrierCache() {
        section("Barrier cache: 12 concurrent reads/writes")
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            // concurrentPerform runs the body in parallel and blocks until all finish,
            // so we call it off the main thread.
            DispatchQueue.concurrentPerform(iterations: 12) { i in
                let key = "key\(i % 3)"
                if i % 2 == 0 {
                    self.cache.set("v\(i)", for: key)
                    self.log("write \(key) = v\(i)")
                } else {
                    let value = self.cache.value(for: key) ?? "nil"
                    self.log("read  \(key) -> \(value)")
                }
            }
            self.log("cache done, count = \(self.cache.count)")
        }
    }

    // MARK: - 4. DispatchWorkItem — cooperative cancellation + asyncAfter

    private func runCancellable() {
        section("WorkItem: cancel() only stops at the next isCancelled check")
        var work: DispatchWorkItem!
        work = DispatchWorkItem { [weak self] in
            for i in 1...10 {
                if work.isCancelled {                             // cooperative: we check by hand
                    self?.log("cancelled at step \(i)")
                    return
                }
                self?.log("step \(i)")
                Thread.sleep(forTimeInterval: 0.3)
            }
            self?.log("finished all steps")
        }
        DispatchQueue.global(qos: .utility).async(execute: work)

        // Cancel ~1s later. Steps already running won't be interrupted mid-sleep;
        // the loop stops at the next isCancelled check.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.log("calling cancel()")
            work.cancel()
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        let stamp = String(format: "%6.3fs", Date().timeIntervalSince(startTime))
        let onMain = Thread.isMainThread ? "main" : "bg  "
        logQueue.async {
            self.logBuffer += "[\(stamp) | \(onMain)]  \(message)\n"
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

// MARK: - A thread-safe cache using the reader/writer (barrier) pattern

/// Concurrent reads, exclusive (barrier) writes — see Module 3 §8.
/// The barrier only works because `queue` is a concurrent queue we created ourselves.
final class SafeCache {
    private var storage: [String: String] = [:]
    private let queue = DispatchQueue(label: "com.fresher2026.safecache", attributes: .concurrent)

    func value(for key: String) -> String? {
        queue.sync { storage[key] }                       // many reads can run at once
    }

    func set(_ value: String, for key: String) {
        queue.async(flags: .barrier) {                    // write runs alone
            self.storage[key] = value
        }
    }

    var count: Int {
        queue.sync { storage.count }
    }
}
