//
//  PhotoCell.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//


import UIKit

// MARK: - PhotoCell

final class PhotoCell: UICollectionViewCell {

    static let reuseID = "PhotoCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    private let favoriteBadge: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "star.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemYellow
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [imageView, captionLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        contentView.addSubview(favoriteBadge)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            favoriteBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            favoriteBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            favoriteBadge.widthAnchor.constraint(equalToConstant: 18),
            favoriteBadge.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    /// Fill the cell from a model item. Sets EVERY visible property so a
    /// recycled cell never shows leftover content.
    func configure(with photo: Photo) {
        imageView.image = UIImage(systemName: photo.symbolName)
        captionLabel.text = photo.caption
        favoriteBadge.isHidden = !photo.isFavorite
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        captionLabel.text = nil
        favoriteBadge.isHidden = true
    }
}

// MARK: - SectionHeaderView (supplementary view)

final class SectionHeaderView: UICollectionReusableView {

    static let reuseID = "SectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
