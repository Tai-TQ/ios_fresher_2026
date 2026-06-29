//
//  OperationPipelinePlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 23/6/26.
//
//  Module 4 — Operation & OperationQueue. A simulated download → parse → cache
//  pipeline wired with dependencies, run on an OperationQueue with a concurrency
//  cap. Includes a reusable AsyncOperation base class (the KVO state machine) and
//  a custom DownloadOperation. Downloads are simulated with asyncAfter (no network).
//
//  Menu line (add to ViewController.swift):
//    addButton(title: "Operation Pipeline") { [weak self] in
//        self?.navigationController?.pushViewController(OperationPipelinePlayground(), animated: true)
//    }
//
//  iOS 15+ (uses UIButton.Configuration). No assets — SF Symbols only.
//

import UIKit

final class OperationPipelinePlayground: UIViewController {

    // MARK: - State

    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.fresher2026.pipeline"
        q.maxConcurrentOperationCount = 2     // at most 2 operations run at once
        q.qualityOfService = .userInitiated
        return q
    }()

    // Serial queue that owns the log buffer (true cross-thread order).
    private let logQueue = DispatchQueue(label: "com.fresher2026.op.log")
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
        title = "Operation Pipeline"
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue.cancelAllOperations()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(makeButton("Run pipeline (1 item)", "arrow.down.doc") { [weak self] in self?.runOne() })
        buttonStack.addArrangedSubview(makeButton("Run 5 items (max 2)", "rectangle.stack") { [weak self] in self?.runFive() })
        buttonStack.addArrangedSubview(makeButton("Cancel all", "xmark.octagon") { [weak self] in self?.cancelAll() })
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

    private func runOne() {
        section("Pipeline: 1 item (download → parse → cache)")
        queue.addOperations(makePipeline(id: 1), waitUntilFinished: false)   // never block main
    }

    private func runFive() {
        section("5 items, maxConcurrentOperationCount = \(queue.maxConcurrentOperationCount)")
        var all: [Operation] = []
        for id in 1...5 { all += makePipeline(id: id) }
        queue.addOperations(all, waitUntilFinished: false)
    }

    private func cancelAll() {
        section("cancelAllOperations()")
        log("cancelling — not-yet-started ops are skipped; running ones stop only if they check isCancelled")
        queue.cancelAllOperations()
    }

    /// Build a download → parse → cache chain for one item, wired with dependencies.
    private func makePipeline(id: Int) -> [Operation] {
        let download = DownloadOperation(id: id)
        download.onLog = { [weak self] in self?.log($0) }

        // parse depends on download, so download.output is ready when this runs.
        let parse = BlockOperation { [weak self, weak download] in
            guard let self else { return }
            guard let data = download?.output else {
                self.log("parse \(id): skipped (no data — likely cancelled)")
                return
            }
            self.log("parse \(id): parsed \(data)")
        }
        parse.addDependency(download)

        let cache = BlockOperation { [weak self] in
            self?.log("cache \(id): stored")
        }
        cache.addDependency(parse)

        return [download, parse, cache]
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

// MARK: - Reusable asynchronous Operation base class (the KVO state machine)

/// Models async work on an OperationQueue. The queue observes isExecuting / isFinished
/// via KVO; we fire those notifications from the `state` setter. See Module 4 §8.
class AsyncOperation: Operation, @unchecked Sendable {

    enum State: String {
        case ready, executing, finished
        // KVO keys the queue listens to: "isReady", "isExecuting", "isFinished".
        fileprivate var keyPath: String { "is" + rawValue.capitalized }
    }

    var state: State = .ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }

    override var isAsynchronous: Bool { true }
    override var isExecuting: Bool { state == .executing }
    override var isFinished: Bool  { state == .finished }

    override func start() {
        // Handles the "cancelled before it started" case for free.
        if isCancelled {
            state = .finished
            return
        }
        state = .executing
        main()
    }
}

// MARK: - A concrete async operation: a simulated download

final class DownloadOperation: AsyncOperation, @unchecked Sendable {
    let id: Int
    private(set) var output: String?
    var onLog: ((String) -> Void)?

    init(id: Int) { self.id = id }

    override func main() {
        onLog?("download \(id): start")
        // Simulate a network call. asyncAfter stands in for the completion handler.
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Double.random(in: 0.3...0.9)) { [weak self] in
            guard let self else { return }
            if self.isCancelled {                       // cooperative cancellation check
                self.onLog?("download \(self.id): cancelled — skip work")
            } else {
                self.output = "data-\(self.id)"
                self.onLog?("download \(self.id): finished")
            }
            self.state = .finished                      // ⚠️ MUST set this or the queue stalls (§8, §10)
        }
    }
}
