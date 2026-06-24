//
//  ViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 19/6/26.
//

import UIKit

final class ViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Demo"

        setupStackView()
        addDemoButtons()
    }

    private func setupStackView() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            // Scroll view fills the safe area.
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Pin the stack to the scroll view's CONTENT guide (this defines scrollable size).
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),

            // Width is driven by the FRAME guide, so it scrolls vertically (not horizontally).
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    private func addDemoButtons() {
        addButton(title: "Components") { [weak self] in
            self?.navigationController?.pushViewController(DemoComponentVC(), animated: true)
        }
        addButton(title: "Table View") { [weak self] in
            self?.navigationController?.pushViewController(DemoTableViewController(), animated: true)
        }
        addButton(title: "Collection View") { [weak self] in
            self?.navigationController?.pushViewController(DemoCollectionViewController(), animated: true)
        }
        addButton(title: "Navigation") { [weak self] in
            self?.navigationController?.pushViewController(DemoNavigationViewController(), animated: true)
        }
        addButton(title: "Animation") { [weak self] in
            self?.navigationController?.pushViewController(DemoAnimationViewController(), animated: true)
        }
        addButton(title: "UI Debugging") { [weak self] in
            self?.navigationController?.pushViewController(DebuggingPlayground(), animated: true)
        }
        
        addButton(title: "Threading Fundamentals") { [weak self] in
            self?.navigationController?.pushViewController(ThreadingPlayground(), animated: true)
        }
        
        addButton(title: "Concurrency Concepts") { [weak self] in
            self?.navigationController?.pushViewController(ExecutionOrderPlayground(), animated: true)
        }
        
        addButton(title: "GCD — Queues & Deadlock") { [weak self] in
            self?.navigationController?.pushViewController(GCDQueuesPlayground(), animated: true)
        }
        
        addButton(title: "GCD — Coordination Tools") { [weak self] in
            self?.navigationController?.pushViewController(GCDCoordinationPlayground(), animated: true)
        }
        
        addButton(title: "Operation Pipeline") { [weak self] in
            self?.navigationController?.pushViewController(OperationPipelinePlayground(), animated: true)
        }
        
        addButton(title: "Async/Await vs GCD") { [weak self] in
            self?.navigationController?.pushViewController(AsyncAwaitComparisonPlayground(), animated: true)
        }
        
        addButton(title: "Concurrency Bugs") { [weak self] in
            self?.navigationController?.pushViewController(ConcurrencyBugsPlayground(), animated: true)
        }
        
    }
    
    private func addButton(title: String, action: @escaping () -> Void) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
}
