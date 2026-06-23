//
//  ThreadingPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//

import UIKit

final class ThreadingPlayground: UIViewController {

    // MARK: - State

    /// Heartbeat: how many tenths-of-a-second have elapsed since the screen appeared.
    /// It is driven by a Timer that fires on the MAIN run loop — so the moment the
    /// main thread is blocked, this stops advancing. That frozen number is our proof.
    private var heartbeatTicks = 0
    private var heartbeatTimer: Timer?

    // MARK: - Views

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let heartbeatLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 28, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "❤️ Heartbeat\n0.0s"
        return label
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Tap a button. Watch the heartbeat."
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Threading Fundamentals"
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startHeartbeat()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Always invalidate timers when leaving — a live timer retains its target.
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])

        stackView.addArrangedSubview(heartbeatLabel)
        stackView.addArrangedSubview(makeButton(
            title: "Block Main Thread (5s)",
            symbol: "exclamationmark.triangle.fill",
            style: .tinted,
            action: { [weak self] in self?.runOnMainThread() }
        ))
        stackView.addArrangedSubview(makeButton(
            title: "Run on Background (5s)",
            symbol: "checkmark.circle.fill",
            style: .filled,
            action: { [weak self] in self?.runOnBackground() }
        ))
        stackView.addArrangedSubview(resultLabel)
    }

    // MARK: - The heartbeat (proof the main thread is alive)

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTicks = 0
        // Fires on the main run loop. When the main thread is busy, this can't fire —
        // which is exactly what makes the freeze visible.
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.heartbeatTicks += 1
            let seconds = Double(self.heartbeatTicks) / 10.0
            self.heartbeatLabel.text = String(format: "❤️ Heartbeat\n%.1fs", seconds)
        }
    }

    // MARK: - Actions

    /// ❌ The wrong way: do slow work directly on the main thread.
    /// The button handler runs on main, so the run loop can't redraw or fire the
    /// timer until heavyWork() returns. The heartbeat freezes for 5 seconds.
    private func runOnMainThread() {
        resultLabel.text = "Working on the MAIN thread… UI is frozen."
        let result = heavyWork()           // ← blocks the main thread for ~5s
        resultLabel.text = result
    }

    /// ✅ The right way: slow work OFF main, UI update BACK ON main.
    /// The heartbeat keeps ticking because the main thread is free.
    private func runOnBackground() {
        resultLabel.text = "Working on a BACKGROUND thread… UI stays alive."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result = self.heavyWork()  // ← runs off the main thread

            // 🐞 BUG (Lab 3): touching UIKit off the main thread. Uncomment this,
            //     turn on the Main Thread Checker, and run the background button to
            //     watch it get caught. Then re-comment it.
            // self.resultLabel.text = result

            // ✅ FIX: hop back to the main thread for any UI work.
            DispatchQueue.main.async {
                self.resultLabel.text = result
            }
        }
    }

    // MARK: - Helpers

    /// Simulates ~5 seconds of slow work. We use Thread.sleep so the demo needs no
    /// network — in a real app this would be a download, a file read, or heavy compute.
    private func heavyWork() -> String {
        Thread.sleep(forTimeInterval: 5)
        let where_ = Thread.isMainThread ? "MAIN thread" : "a background thread"
        return "Done — 5s of work finished on \(where_)."
    }

    private func makeButton(
        title: String,
        symbol: String,
        style: ButtonStyle,
        action: @escaping () -> Void
    ) -> UIButton {
        var config: UIButton.Configuration = (style == .filled) ? .filled() : .tinted()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 8
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private enum ButtonStyle { case filled, tinted }
}
