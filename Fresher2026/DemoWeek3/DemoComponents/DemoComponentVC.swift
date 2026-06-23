//
//  DemoComponentVC.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

final class DemoComponentVC: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    // MARK: - State

    private var tapCount = 0

    // MARK: - Views referenced from more than one place

    /// Shows feedback as the user interacts with the controls.
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Interact with the controls below."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .systemBlue
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()

    /// Section 10 — toggled by a button.
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "UIKit Components"

        let contentStack = makeScrollableContentStack()   // Section 2
        populate(contentStack)                             // Sections 1, 3–10
        installKeyboardDismissGesture()
    }

    // MARK: - Section 2: UIScrollView + content stack

    /// Builds the scroll view and the vertical stack that holds all content,
    /// using the iOS 11+ content/frame layout guides.
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
            // Scroll view fills the safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Content pinned to the CONTENT guide (defines what scrolls)
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),

            // Width pinned to the FRAME guide → vertical-only scrolling
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        return contentStack
    }

    // MARK: - Build every component into the content stack

    private func populate(_ stack: UIStackView) {
        // Status label sits at the very top.
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(separator())

        // Section 3 — UILabel
        stack.addArrangedSubview(sectionTitle("3. UILabel"))

        let multilineLabel = UILabel()
        multilineLabel.text = "This is a multi-line label. With numberOfLines set to 0, it wraps to as many lines as the text needs."
        multilineLabel.numberOfLines = 0
        stack.addArrangedSubview(multilineLabel)

        let attributedLabel = UILabel()
        let attr = NSMutableAttributedString(string: "Attributed text: ")
        attr.append(NSAttributedString(string: "bold", attributes: [.font: UIFont.boldSystemFont(ofSize: 17)]))
        attr.append(NSAttributedString(string: ", and "))
        attr.append(NSAttributedString(string: "colored", attributes: [.foregroundColor: UIColor.systemRed]))
        attributedLabel.attributedText = attr
        attributedLabel.numberOfLines = 0
        stack.addArrangedSubview(attributedLabel)
        stack.addArrangedSubview(separator())

        // Section 4 — UIImageView (SF Symbol, no assets required)
        stack.addArrangedSubview(sectionTitle("4. UIImageView"))

        let imageView = UIImageView(image: UIImage(systemName: "star.circle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemYellow
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(separator())

        // Section 5 — UIButton (iOS 15+ Configuration + target-action)
        stack.addArrangedSubview(sectionTitle("5. UIButton"))

        var config = UIButton.Configuration.filled()
        config.title = "Tap me"
        config.baseBackgroundColor = .systemBlue
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        stack.addArrangedSubview(button)
        stack.addArrangedSubview(separator())

        // Section 6 — UITextField (target-action + delegate)
        stack.addArrangedSubview(sectionTitle("6. UITextField"))

        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Type your name, then press Return"
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        stack.addArrangedSubview(textField)
        stack.addArrangedSubview(separator())

        // Section 7 — UITextView (multi-line, editable)
        stack.addArrangedSubview(sectionTitle("7. UITextView"))

        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.text = "An editable, multi-line text view. Set isEditable = false to make it read-only."
        textView.delegate = self
        textView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stack.addArrangedSubview(textView)
        stack.addArrangedSubview(separator())

        // Section 8 — UISwitch (in a labeled row)
        stack.addArrangedSubview(sectionTitle("8. UISwitch"))

        let switchLabel = UILabel()
        switchLabel.text = "Enable feature"
        switchLabel.setContentHuggingPriority(.defaultLow, for: .horizontal) // let label take the slack

        let toggle = UISwitch()
        toggle.isOn = true
        toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)

        let switchRow = UIStackView(arrangedSubviews: [switchLabel, toggle])
        switchRow.axis = .horizontal
        switchRow.alignment = .center
        switchRow.distribution = .fill
        stack.addArrangedSubview(switchRow)
        stack.addArrangedSubview(separator())

        // Section 9 — UISegmentedControl
        stack.addArrangedSubview(sectionTitle("9. UISegmentedControl"))

        let segmented = UISegmentedControl(items: ["One", "Two", "Three"])
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        stack.addArrangedSubview(segmented)
        stack.addArrangedSubview(separator())

        // Section 10 — UIActivityIndicatorView (toggled by a button)
        stack.addArrangedSubview(sectionTitle("10. UIActivityIndicatorView"))

        var spinnerConfig = UIButton.Configuration.tinted()
        spinnerConfig.title = "Start / stop loading"
        let spinnerButton = UIButton(configuration: spinnerConfig)
        spinnerButton.addTarget(self, action: #selector(toggleSpinner), for: .touchUpInside)
        stack.addArrangedSubview(spinnerButton)
        stack.addArrangedSubview(spinner)
    }

    // MARK: - Actions (target-action)

    @objc private func didTapButton() {
        tapCount += 1
        setStatus("Button tapped \(tapCount) time(s)")
    }

    @objc private func textFieldChanged(_ sender: UITextField) {
        setStatus("Text field: \(sender.text ?? "")")
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        setStatus("Switch is \(sender.isOn ? "ON" : "OFF")")
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        setStatus("Selected segment \(sender.selectedSegmentIndex + 1)")
    }

    @objc private func toggleSpinner() {
        if spinner.isAnimating {
            spinner.stopAnimating()
            setStatus("Loading stopped")
        } else {
            spinner.startAnimating()
            setStatus("Loading…")
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()   // dismiss the keyboard
        return true
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        setStatus("Text view has \(textView.text.count) character(s)")
    }

    // MARK: - Helpers

    private func setStatus(_ text: String) {
        statusLabel.text = text
    }

    /// A bold section heading.
    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .label
        return label
    }

    /// A thin horizontal divider line.
    private func separator() -> UIView {
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    /// Tap anywhere outside a text input to dismiss the keyboard.
    private func installKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false   // so taps still reach buttons/switches
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
