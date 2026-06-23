//
//  ViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 19/6/26.
//

import UIKit

final class ViewController: UIViewController {

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
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
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
