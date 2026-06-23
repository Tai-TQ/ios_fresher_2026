//
//  DemoNavigationViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

final class DemoNavigationViewController: UIViewController {

    // MARK: - Data
    // Reuses the `Contact` model declared in DemoTableViewController.swift (same target).

    private var contacts: [Contact] = [
        Contact(name: "Ada Lovelace", role: "Mathematician", isFavorite: true),
        Contact(name: "Alan Turing", role: "Computer scientist", isFavorite: false),
        Contact(name: "Grace Hopper", role: "Rear admiral & computer scientist", isFavorite: true),
        Contact(name: "Katherine Johnson", role: "Mathematician", isFavorite: false),
    ]

    private static let cellID = "Cell"

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Contacts"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addTapped)
        )

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Form → Confirmation (modal present; data comes BACK via a closure)

    @objc private func addTapped() {
        let addVC = AddContactViewController()
        addVC.onSave = { [weak self] newContact in       // [weak self] → no retain cycle
            guard let self else { return }
            self.contacts.append(newContact)
            self.tableView.reloadData()
        }
        // Wrap in its own navigation controller so the modal has a bar with Cancel/Save.
        let nav = UINavigationController(rootViewController: addVC)
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension DemoNavigationViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
        let contact = contacts[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = contact.name
        content.secondaryText = contact.role
        content.image = UIImage(systemName: contact.isFavorite ? "star.fill" : "star")
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DemoNavigationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // List → Detail: PUSH, passing the selected contact FORWARD via the initializer.
        let detailVC = ContactDetailViewController(contact: contacts[indexPath.row])
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - ContactDetailDelegate (the detail screen passes edits BACK to here)

extension DemoNavigationViewController: ContactDetailDelegate {

    func contactDetail(_ controller: ContactDetailViewController, didUpdate contact: Contact) {
        if let i = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[i] = contact          // adopt the updated value
            tableView.reloadData()
        }
    }
}
