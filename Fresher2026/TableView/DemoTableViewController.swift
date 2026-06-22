//
//  DemoTableViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

// MARK: - Model
// Declared at file scope so ContactCell.swift (same target) can see it.

struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    var isFavorite: Bool
}

final class DemoTableViewController: UIViewController {

    // MARK: - Data

    private var contacts: [Contact] = [
        Contact(name: "Ada Lovelace",
                role: "Mathematician · widely regarded as the first computer programmer",
                isFavorite: true),
        Contact(name: "Alan Turing",
                role: "Computer scientist, cryptanalyst, and theoretical biologist",
                isFavorite: false),
        Contact(name: "Grace Hopper",
                role: "Rear admiral and computer scientist who popularized machine-independent programming languages",
                isFavorite: true),
        Contact(name: "Katherine Johnson",
                role: "Mathematician",
                isFavorite: false),
        Contact(name: "Margaret Hamilton",
                role: "Led the team that developed the on-board flight software for NASA's Apollo missions",
                isFavorite: false),
    ]

    private var favorites: [Contact] { contacts.filter { $0.isFavorite } }
    private var others: [Contact]    { contacts.filter { !$0.isFavorite } }

    /// Maps a row position back to its model item.
    private func contact(at indexPath: IndexPath) -> Contact {
        (indexPath.section == 0 ? favorites : others)[indexPath.row]
    }

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension   // self-sizing
        tableView.estimatedRowHeight = 60
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: ContactCell.reuseID)
        tableView.tableHeaderView = makeTableHeader()
    }

    // MARK: - Adding rows

    @objc private func addContact() {
        let n = contacts.count + 1
        let newContact = Contact(name: "New Person \(n)",
                                 role: "Tap to favorite · swipe to delete",
                                 isFavorite: false)
        contacts.append(newContact)
        // A new non-favorite lands at the end of section 1 ("All Contacts").
        let newIndexPath = IndexPath(row: others.count - 1, section: 1)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
    }

    // MARK: - Table header (an "Add" button, visible without a navigation bar)

    private func makeTableHeader() -> UIView {
        // A fixed-height container so UIKit can size the header without
        // Auto Layout gymnastics; the button is centered with constraints.
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 56))

        var config = UIButton.Configuration.tinted()
        config.title = "Add a contact"
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 6
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(addContact), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }
}

// MARK: - UITableViewDataSource

extension DemoTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Favorites" : "All Contacts"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 1 ? "Tap a contact to favorite it. Swipe left to delete." : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? favorites.count : others.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactCell.reuseID,
                                                 for: indexPath) as! ContactCell
        cell.configure(with: contact(at: indexPath))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DemoTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Toggle favorite → the contact moves between sections, so reloadData
        // is the simplest correct update here.
        let tapped = contact(at: indexPath)
        if let i = contacts.firstIndex(where: { $0.id == tapped.id }) {
            contacts[i].isFavorite.toggle()
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let target = contact(at: indexPath)
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { done(false); return }
            if let i = self.contacts.firstIndex(where: { $0.id == target.id }) {
                self.contacts.remove(at: i)                              // model first
                tableView.deleteRows(at: [indexPath], with: .automatic)  // then the table
            }
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
