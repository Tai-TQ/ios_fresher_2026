//
//  GCDQueuesPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//

import UIKit

final class GCDQueuesPlayground: UIViewController {

    // MARK: - Queues

    private let backgroundQueue = DispatchQueue(label: "com.fresher2026.bg", qos: .userInitiated)
    private let serialQueue = DispatchQueue(label: "com.fresher2026.serial")

    // Serial queue that owns the log buffer, so cross-thread logs keep their true order.
    private let logQueue = DispatchQueue(label: "com.fresher2026.log")
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
        title = "GCD — Queues & Deadlock"
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(makeButton("Off-main → on-main hop", "arrow.left.arrow.right") { [weak self] in self?.runHop() })
        buttonStack.addArrangedSubview(makeButton("Custom serial queue (ordered)", "list.number") { [weak self] in self?.runSerial() })
        buttonStack.addArrangedSubview(makeButton("Two QoS levels", "speedometer") { [weak self] in self?.runQoS() })
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

    /// The canonical pattern: slow work off main, UI update back on main.
    private func runHop() {
        section("Off-main → on-main")
        log("tapped (UI)")
        backgroundQueue.async { [weak self] in
            guard let self else { return }
            self.log("decoding… (slow work)")
            Thread.sleep(forTimeInterval: 1.0)          // simulate a decode/download
            self.log("decoded")
            DispatchQueue.main.async {
                self.log("update UI")                   // must be on main
            }
        }
    }

    /// A custom serial queue runs submitted work one at a time, in order.
    private func runSerial() {
        section("Custom serial queue")
        for name in ["A", "B", "C"] {
            serialQueue.async { [weak self] in
                guard let self else { return }
                self.log("\(name) start")
                Thread.sleep(forTimeInterval: 0.3)
                self.log("\(name) end")
            }
        }
    }

    /// Submit work at two different QoS levels and log when each runs. The
    /// .userInitiated work is generally scheduled ahead of the .background work.
    private func runQoS() {
        section("Two QoS levels")
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.log("background QoS — low priority work")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.log("userInitiated QoS — user is waiting")
        }
    }

    // 🐞 BUG (Lab 2): the classic GCD deadlock. We are already on the main thread
    //     (button actions run on main), and we ask the main SERIAL queue to run a
    //     block synchronously — but main is busy running this code, so it can never
    //     free up to run the block. The app freezes. Wire this to a button, run,
    //     stop it in Xcode, inspect the main thread's stack, then re-comment.
    //
    // private func runDeadlock() {
    //     section("DEADLOCK — main.sync on the main thread")
    //     log("before")
    //     DispatchQueue.main.sync {     // 💥 deadlock
    //         self.log("inside (never runs)")
    //     }
    //     log("after (never runs)")
    // }

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
