//
//  ContactCell.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

final class ContactCell: UITableViewCell {

    /// Central reuse identifier — referenced by the view controller so a typo
    /// can never cause a dequeue crash.
    static let reuseID = "ContactCell"

    // MARK: - Subviews

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        return label
    }()

    private let roleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0          // multi-line → drives self-sizing
        return label
    }()

    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        accessoryType = .disclosureIndicator

        let textStack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [avatarImageView, textStack, starImageView])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)

        // Pinning the row stack to BOTH top and bottom of the content view's
        // margins gives an unbroken vertical chain → the cell self-sizes.
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: margins.topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),

            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            starImageView.widthAnchor.constraint(equalToConstant: 22),
        ])
    }

    // MARK: - Configuration

    /// Fill the cell from a model item. Sets EVERY visible property so a
    /// recycled cell never shows leftover content from a previous row.
    func configure(with contact: Contact) {
        nameLabel.text = contact.name
        roleLabel.text = contact.role
        starImageView.image = UIImage(systemName: contact.isFavorite ? "star.fill" : "star")
        starImageView.tintColor = contact.isFavorite ? .systemYellow : .systemGray4
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        roleLabel.text = nil
        starImageView.image = nil
    }
}
