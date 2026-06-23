//
//  DemoCollectionViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

// MARK: - Model
// Declared at file scope so PhotoCell.swift (same target) can see it.

struct Photo {
    let symbolName: String
    let caption: String
    var isFavorite: Bool
}

struct Category {
    let title: String
    var photos: [Photo]
}

final class DemoCollectionViewController: UIViewController {

    // MARK: - Data

    private var categories: [Category] = [
        Category(title: "Shapes", photos: [
            Photo(symbolName: "star.fill",     caption: "Star",     isFavorite: true),
            Photo(symbolName: "heart.fill",    caption: "Heart",    isFavorite: false),
            Photo(symbolName: "flag.fill",     caption: "Flag",     isFavorite: false),
            Photo(symbolName: "bell.fill",     caption: "Bell",     isFavorite: false),
            Photo(symbolName: "bookmark.fill", caption: "Bookmark", isFavorite: false),
            Photo(symbolName: "gift.fill",     caption: "Gift",     isFavorite: true),
        ]),
        Category(title: "Weather", photos: [
            Photo(symbolName: "sun.max.fill", caption: "Sun",      isFavorite: false),
            Photo(symbolName: "cloud.fill",   caption: "Cloud",    isFavorite: false),
            Photo(symbolName: "bolt.fill",    caption: "Bolt",     isFavorite: true),
            Photo(symbolName: "moon.fill",    caption: "Moon",     isFavorite: false),
            Photo(symbolName: "flame.fill",   caption: "Flame",    isFavorite: false),
            Photo(symbolName: "sparkles",     caption: "Sparkles", isFavorite: false),
        ]),
        Category(title: "Home", photos: [
            Photo(symbolName: "house.fill",    caption: "House",   isFavorite: false),
            Photo(symbolName: "cart.fill",     caption: "Cart",    isFavorite: false),
            Photo(symbolName: "camera.fill",   caption: "Camera",  isFavorite: true),
            Photo(symbolName: "envelope.fill", caption: "Mail",    isFavorite: false),
            Photo(symbolName: "folder.fill",   caption: "Folder",  isFavorite: false),
            Photo(symbolName: "gear",          caption: "Settings", isFavorite: false),
        ]),
    ]

    private func photo(at indexPath: IndexPath) -> Photo {
        categories[indexPath.section].photos[indexPath.item]
    }

    // MARK: - Views

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        layout.headerReferenceSize = CGSize(width: 0, height: 44)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.alwaysBounceVertical = true
        return cv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCell.self,
                                forCellWithReuseIdentifier: PhotoCell.reuseID)
        collectionView.register(SectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SectionHeaderView.reuseID)
    }
}

// MARK: - UICollectionViewDataSource

extension DemoCollectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        categories.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        categories[section].photos.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseID,
                                                      for: indexPath) as! PhotoCell
        cell.configure(with: photo(at: indexPath))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SectionHeaderView.reuseID,
            for: indexPath) as! SectionHeaderView
        header.configure(title: categories[indexPath.section].title)
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension DemoCollectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        categories[indexPath.section].photos[indexPath.item].isFavorite.toggle()
        collectionView.reloadItems(at: [indexPath])   // refresh just that one item
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DemoCollectionViewController: UICollectionViewDelegateFlowLayout {
        
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 3
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let interitem = layout.minimumInteritemSpacing * (columns - 1)
        let insets = layout.sectionInset.left + layout.sectionInset.right
        let available = collectionView.bounds.width - interitem - insets
        let side = floor(available / columns)         // floor avoids the "item too wide" warning
        return CGSize(width: side, height: side + 28) // square image + caption strip
    }
}
