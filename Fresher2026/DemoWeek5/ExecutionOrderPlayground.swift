//
//  ExecutionOrderPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//
//  Module 2 — Concurrency Concepts. "Predict the order" playground: each button
//  runs a scenario (sync / async / serial ×3 / concurrent ×3) and appends a
//  timestamped log so the execution order is visible on screen. Compare what you
//  predicted (using the §3 2×2 grid) with what actually printed.
//
//  Menu line (add to ViewController.swift):
//    addButton(title: "Concurrency Concepts") { [weak self] in
//        self?.navigationController?.pushViewController(ExecutionOrderPlayground(), animated: true)
//    }
//
//  iOS 15+ (uses UIButton.Configuration). No assets — SF Symbols only.
//  Uses minimal GCD purely to demonstrate scheduling; the API is taught in Module 3.
//

import UIKit

final class ExecutionOrderPlayground: UIViewController {

    // MARK: - Queues (just enough GCD for the demo — see Module 3)

    private let serialQueue = DispatchQueue(label: "demo.serial")                       // one lane
    private let concurrentQueue = DispatchQueue(label: "demo.concurrent",
                                                attributes: .concurrent)                // many lanes

    /// A private serial queue that owns the log buffer. Because only this queue ever
    /// touches `logBuffer`, access is automatically serialised — a tiny preview of
    /// "use a serial queue to protect shared state" (Module 6). It also means the log
    /// records events in the true order they happened, across threads.
    private let logQueue = DispatchQueue(label: "demo.log")
    private var logBuffer = ""
    private let startTime = Date()

    // MARK: - Views

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
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
        title = "Concurrency Concepts"
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(makeButton("Sync (1·2·3)", "arrow.down.to.line") { [weak self] in self?.runSync() })
        buttonStack.addArrangedSubview(makeButton("Async (1·3·2)", "arrow.uturn.right") { [weak self] in self?.runAsync() })
        buttonStack.addArrangedSubview(makeButton("Serial async ×3", "1.square") { [weak self] in self?.runSerial() })
        buttonStack.addArrangedSubview(makeButton("Concurrent async ×3", "square.grid.2x2") { [weak self] in self?.runConcurrent() })
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

    // MARK: - Scenarios

    /// SYNC: the caller waits. Output is always 1, 2, 3.
    private func runSync() {
        section("SYNC — caller waits")
        log("1")
        serialQueue.sync { log("2") }   // caller blocks here until the block finishes
        log("3")
    }

    /// ASYNC: the caller does NOT wait. Output is 1, 3, 2 — "3" runs before "2".
    private func runAsync() {
        section("ASYNC — caller does not wait")
        log("1")
        serialQueue.async { self.log("2") }   // handed off; we move on immediately
        log("3")
    }

    /// SERIAL: one lane. Always A start, A end, B start, B end, C start, C end.
    private func runSerial() {
        section("SERIAL async ×3 — ordered")
        for name in ["A", "B", "C"] {
            serialQueue.async {
                self.log("\(name) start")
                Thread.sleep(forTimeInterval: 0.3)   // simulate a little work
                self.log("\(name) end")
            }
        }
    }

    /// CONCURRENT: many lanes. All three start near-together; finish order varies run to run.
    private func runConcurrent() {
        section("CONCURRENT async ×3 — overlapping, order NOT guaranteed")
        for name in ["A", "B", "C"] {
            concurrentQueue.async {
                self.log("\(name) start")
                Thread.sleep(forTimeInterval: 0.3)
                self.log("\(name) end")
            }
        }
    }

    // 🐞 BUG (Lab 4): calling .sync on the MAIN queue while already on the main thread
    //     deadlocks — main waits for a block that can only run when main is free.
    //     Uncomment, wire to a button, run, and watch the app freeze. Then re-comment.
    //
    // private func runDeadlock() {
    //     section("DEADLOCK — do not ship this")
    //     log("before")
    //     DispatchQueue.main.sync { self.log("inside") }   // 💥 deadlock
    //     log("after")
    // }

    // MARK: - Logging (records true cross-thread order via a serial queue)

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

    /// Render the buffer to the UI. Always hops to the main thread — UIKit rule (Module 1).
    private func render() {
        let snapshot = logBuffer
        DispatchQueue.main.async {
            self.textView.text = snapshot
            let end = NSRange(location: snapshot.count, length: 0)
            self.textView.scrollRangeToVisible(end)
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
