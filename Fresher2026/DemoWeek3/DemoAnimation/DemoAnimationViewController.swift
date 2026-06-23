//
//  DemoAnimationViewController.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//
//  One screen with three animation exercises:
//    1. Login Button       — tap feedback (scale + spring), reset with .identity
//    2. Expandable Card     — constraint animation (isActive toggle) + chevron rotation
//    3. Success Transition  — fade out → spinner → checkmark springs in (completion chaining)
//

import UIKit

final class DemoAnimationViewController: UIViewController {

    // MARK: - State

    private var isCardExpanded = false

    // MARK: - Exercise 1 — Login Button

    private lazy var loginButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Log In"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Exercise 2 — Expandable Card

    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let cardDetailLabel = UILabel()
    /// A "height = 0" constraint we ACTIVATE to collapse and DEACTIVATE to expand.
    private var cardCollapsedConstraint: NSLayoutConstraint?

    // MARK: - Exercise 3 — Success State Transition

    private lazy var submitButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Submit"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return button
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private let checkmark: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 44)
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: config))
        imageView.tintColor = .systemGreen
        imageView.isHidden = true
        imageView.alpha = 0
        return imageView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Animations"

        let contentStack = makeScrollableContentStack()
        populate(contentStack)
    }

    // MARK: - Scroll container (so the expanding card never clips)

    private func makeScrollableContentStack() -> UIStackView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        return contentStack
    }

    private func populate(_ stack: UIStackView) {
        stack.addArrangedSubview(sectionTitle("1. Login Button — tap feedback (scale + spring)"))
        stack.addArrangedSubview(loginButton)
        stack.addArrangedSubview(hint("Tap the button to feel the press animation."))
        stack.addArrangedSubview(separator())

        stack.addArrangedSubview(sectionTitle("2. Expandable Card — constraint animation"))
        stack.addArrangedSubview(makeCard())
        stack.addArrangedSubview(separator())

        stack.addArrangedSubview(sectionTitle("3. Success State Transition"))
        stack.addArrangedSubview(makeSuccessContainer())
        stack.addArrangedSubview(hint("Tap Submit: it fades out, a spinner runs, then a checkmark springs in."))
    }

    // MARK: - Exercise 1: press feedback

    @objc private func loginTapped() {
        // Scale down quickly...
        UIView.animate(withDuration: 0.1, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState],
                       animations: {
            self.loginButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: { _ in
            // ...then spring back to the original size.
            UIView.animate(withDuration: 0.4, delay: 0,
                           usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5,
                           options: [.beginFromCurrentState],
                           animations: {
                self.loginButton.transform = .identity   // reset
            })
        })
    }

    // MARK: - Exercise 2: expandable card

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.clipsToBounds = true                     // clip the detail when collapsed
        card.translatesAutoresizingMaskIntoConstraints = false

        let headerTitle = UILabel()
        headerTitle.text = "Tap to expand"
        headerTitle.font = .preferredFont(forTextStyle: .headline)
        headerTitle.setContentHuggingPriority(.defaultLow, for: .horizontal)

        chevron.tintColor = .secondaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let header = UIStackView(arrangedSubviews: [headerTitle, chevron])
        header.axis = .horizontal
        header.alignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)

        cardDetailLabel.text = "These details slide open and closed by toggling a height constraint, "
            + "while the chevron rotates with a transform — both inside one animation block."
        cardDetailLabel.font = .preferredFont(forTextStyle: .subheadline)
        cardDetailLabel.textColor = .secondaryLabel
        cardDetailLabel.numberOfLines = 0
        cardDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardDetailLabel)

        // When ACTIVE this pins the detail height to 0 (collapsed). Deactivating it
        // lets the label assume its natural multi-line height (expanded) — no magic number.
        cardCollapsedConstraint = cardDetailLabel.heightAnchor.constraint(equalToConstant: 0)
        cardCollapsedConstraint?.isActive = true

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            cardDetailLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            cardDetailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardDetailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardDetailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleCard))
        card.addGestureRecognizer(tap)
        return card
    }

    @objc private func toggleCard() {
        isCardExpanded.toggle()
        // 1) change the constraint
        cardCollapsedConstraint?.isActive = !isCardExpanded
        // 2) animate the layout pass (and rotate the chevron in the same block)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.chevron.transform = self.isCardExpanded
                ? CGAffineTransform(rotationAngle: .pi)
                : .identity
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Exercise 3: success state transition

    private func makeSuccessContainer() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 56).isActive = true

        // Submit button, spinner, and checkmark share the same center — only one shows at a time.
        for subview in [submitButton, spinner, checkmark] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(subview)
            NSLayoutConstraint.activate([
                subview.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                subview.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
        }
        return container
    }

    @objc private func submitTapped() {
        // Step 1: fade + scale the button out.
        UIView.animate(withDuration: 0.25, animations: {
            self.submitButton.alpha = 0
            self.submitButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            self.submitButton.isHidden = true

            // Step 2: show the spinner and simulate work.
            self.spinner.startAnimating()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.spinner.stopAnimating()
                self.showSuccess()           // Step 3
            }
        })
    }

    private func showSuccess() {
        checkmark.alpha = 0
        checkmark.isHidden = false
        checkmark.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        // The checkmark springs in.
        UIView.animate(withDuration: 0.5, delay: 0,
                       usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5,
                       options: [],
                       animations: {
            self.checkmark.alpha = 1
            self.checkmark.transform = .identity
        }, completion: { _ in
            // Reset after a short pause so the demo can be replayed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.resetSuccessDemo()
            }
        })
    }

    private func resetSuccessDemo() {
        UIView.animate(withDuration: 0.3, animations: {
            self.checkmark.alpha = 0
        }, completion: { _ in
            self.checkmark.isHidden = true
            self.checkmark.transform = .identity
            self.submitButton.transform = .identity
            self.submitButton.alpha = 1
            self.submitButton.isHidden = false
        })
    }

    // MARK: - Helpers

    /// A bold section heading.
    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }

    /// Small grey hint text.
    private func hint(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        return label
    }

    /// A thin horizontal divider line.
    private func separator() -> UIView {
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }
}
