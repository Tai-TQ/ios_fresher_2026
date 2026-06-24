//
//  AsyncAwaitComparisonPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//
//  Module 5 — Swift Concurrency (read & understand). The SAME task implemented with
//  GCD completion handlers and with async/await, side by side; a sequential vs
//  `async let` timing comparison; a withCheckedContinuation bridge around a callback
//  API; and a cancellable task group. All "network" calls are simulated.
//
//  Menu line (add to ViewController.swift):
//    addButton(title: "Async/Await vs GCD") { [weak self] in
//        self?.navigationController?.pushViewController(AsyncAwaitComparisonPlayground(), animated: true)
//    }
//
//  iOS 15+ (UIButton.Configuration; Swift Concurrency). No assets — SF Symbols only.
//

import UIKit

final class AsyncAwaitComparisonPlayground: UIViewController {

    // MARK: - State

    private var groupTask: Task<Void, Never>?

    private let logQueue = DispatchQueue(label: "com.fresher2026.async.log")
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
        title = "Async/Await vs GCD"
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        groupTask?.cancel()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(makeButton("GCD nested completion", "arrow.triangle.branch") { [weak self] in self?.runGCD() })
        buttonStack.addArrangedSubview(makeButton("async / await", "arrow.forward") { [weak self] in self?.runAsync() })
        buttonStack.addArrangedSubview(makeButton("Sequential vs async let", "timer") { [weak self] in self?.runTiming() })
        buttonStack.addArrangedSubview(makeButton("Continuation bridge", "arrow.triangle.2.circlepath") { [weak self] in self?.runBridge() })
        buttonStack.addArrangedSubview(makeButton("Task group + cancel", "xmark.octagon") { [weak self] in self?.runGroup() })
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

    // MARK: - Simulated APIs (async versions)

    private func loadProfile() async -> String {
        try? await Task.sleep(nanoseconds: 500_000_000)        // ~0.5s
        return "Profile(Zalo)"
    }

    private func loadAvatar(for profile: String) async -> String {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return "Avatar(\(profile))"
    }

    // MARK: - Simulated APIs (GCD/callback versions)

    private func loadProfileGCD(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { completion("Profile(Zalo)") }
    }

    private func loadAvatarGCD(for profile: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { completion("Avatar(\(profile))") }
    }

    /// An old callback-based API we want to call with `await` (section 9).
    private func loadLegacy(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { completion("LegacyData") }
    }

    /// The thin async wrapper around it. Resume EXACTLY once.
    private func loadLegacy() async -> String {
        await withCheckedContinuation { continuation in
            loadLegacy { data in
                continuation.resume(returning: data)
            }
        }
    }

    // MARK: - Scenarios

    /// GCD: result flows out through nested completion handlers.
    private func runGCD() {
        section("GCD — nested completion handlers")
        loadProfileGCD { [weak self] profile in
            self?.log("got \(profile)")
            self?.loadAvatarGCD(for: profile) { avatar in
                // Manually hop to main for the "UI" update.
                DispatchQueue.main.async { self?.log("got \(avatar) → show on UI") }
            }
        }
    }

    /// async/await: same logic, straight-line.
    private func runAsync() {
        section("async / await — straight-line")
        Task { [weak self] in
            guard let self else { return }
            let profile = await self.loadProfile()
            self.log("got \(profile)")
            let avatar = await self.loadAvatar(for: profile)
            self.log("got \(avatar) → show on UI")
        }
    }

    /// Sequential awaits (~1.0s) vs concurrent async let (~0.5s).
    private func runTiming() {
        section("Sequential vs async let")
        Task { [weak self] in
            guard let self else { return }

            let t0 = Date()
            _ = await self.loadProfile()
            _ = await self.loadAvatar(for: "x")
            self.log(String(format: "sequential await: %.2fs (~1.0s expected)", Date().timeIntervalSince(t0)))

            let t1 = Date()
            async let a = self.loadProfile()
            async let b = self.loadAvatar(for: "x")
            _ = await (a, b)                                   // both ran in parallel
            self.log(String(format: "async let:        %.2fs (~0.5s expected)", Date().timeIntervalSince(t1)))
        }
    }

    /// Calling a callback API as if it were async, via the continuation wrapper.
    private func runBridge() {
        section("withCheckedContinuation — bridge a callback API")
        Task { [weak self] in
            guard let self else { return }
            let data = await self.loadLegacy()                 // awaiting an old callback API
            self.log("bridged legacy → \(data)")
        }
    }

    /// A dynamic number of parallel downloads, cancellable as one unit.
    private func runGroup() {
        section("Task group — concurrent downloads, cancellable")
        groupTask?.cancel()
        groupTask = Task { [weak self] in
            guard let self else { return }
            do {
                let results = try await withThrowingTaskGroup(of: String.self) { group in
                    for i in 1...5 {
                        group.addTask {
                            try await Task.sleep(nanoseconds: UInt64(i) * 300_000_000)  // throws if cancelled
                            try Task.checkCancellation()
                            return "item\(i)"
                        }
                    }
                    var out: [String] = []
                    for try await item in group {
                        self.log("downloaded \(item)")
                        out.append(item)
                    }
                    return out
                }
                self.log("group finished: \(results.count) items")
            } catch {
                self.log("group cancelled (\(type(of: error)))")
            }
        }

        // Cancel mid-run to show cooperative cancellation propagating to children.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.log("called task.cancel()")
            self?.groupTask?.cancel()
        }
    }

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
