//
//  AddContactViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

final class AddContactViewController: UIViewController {

    // MARK: - Output (data passed BACK via a closure callback)

    var onSave: ((Contact) -> Void)?

    // MARK: - Views

    private let nameField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Name"
        return field
    }()

    private let roleField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Role"
        return field
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "New Contact"

        // Bar buttons on the modal's own navigation controller.
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        let stack = UIStackView(arrangedSubviews: [nameField, roleField])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        nameField.becomeFirstResponder()
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)        // no data passed back
    }

    @objc private func saveTapped() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            nameField.becomeFirstResponder()   // simple validation: name is required
            return
        }
        let role = (roleField.text ?? "").trimmingCharacters(in: .whitespaces)
        let newContact = Contact(name: name,
                                 role: role.isEmpty ? "No role" : role,
                                 isFavorite: false)

        onSave?(newContact)            // hand the new value BACK to the presenter
        dismiss(animated: true)
    }
}
