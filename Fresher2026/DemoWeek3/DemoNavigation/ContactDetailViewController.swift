//
//  ContactDetailViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

// MARK: - Delegate
// Lets the detail screen pass edits BACK to whoever presented it,
// without knowing who that is. `AnyObject` so the delegate can be `weak`.

protocol ContactDetailDelegate: AnyObject {
    func contactDetail(_ controller: ContactDetailViewController, didUpdate contact: Contact)
}

final class ContactDetailViewController: UIViewController {

    // MARK: - Input (passed FORWARD via the initializer)

    private var contact: Contact

    weak var delegate: ContactDetailDelegate?     // weak → no retain cycle

    // MARK: - Init

    init(contact: Contact) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Views

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.numberOfLines = 0
        return label
    }()

    private let roleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(configuration: .tinted())
        button.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        render()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Detail"

        let stack = UIStackView(arrangedSubviews: [nameLabel, roleLabel, favoriteButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    // MARK: - Render the screen from the current model value

    private func render() {
        nameLabel.text = contact.name
        roleLabel.text = contact.role
        var config = favoriteButton.configuration
        config?.title = contact.isFavorite ? "★ Favorited" : "☆ Add to Favorites"
        favoriteButton.configuration = config
    }

    // MARK: - Edit, then pass the change BACK via the delegate

    @objc private func toggleFavorite() {
        contact.isFavorite.toggle()
        render()
        delegate?.contactDetail(self, didUpdate: contact)
    }
}
