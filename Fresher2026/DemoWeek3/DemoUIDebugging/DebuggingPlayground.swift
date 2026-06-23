//
//  DebuggingPlayground.swift
//  Fresher2026
//
//  Created by TaiTQ2 on 22/6/26.
//

import UIKit

final class DebuggingPlayground: UIViewController {

    private enum Bug {
        case ambiguous      // §6 — missing a position constraint (no warning; hasAmbiguousLayout == true)
        case frame          // §6 — forgot translatesAutoresizingMaskIntoConstraints (NSAutoresizingMask… warning)
        case overlap        // §6 — a view hidden behind another (no warning; find it in the 3D hierarchy)
        case conflict       // §6 — two contradictory required constraints ("Unable to simultaneously satisfy")
        case selfSizing     // §7 — a no-warning bug: label truncates because numberOfLines == 1
    }

    /// 👇 Switch this to explore each bug.
    private let activeBug: Bug = .ambiguous

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Debugging Playground"

        switch activeBug {
        case .ambiguous:  setupAmbiguous()
        case .frame:      setupForgotTranslates()
        case .overlap:    setupOverlap()
        case .conflict:   setupConflict()
        case .selfSizing: setupSelfSizingTruncation()
        }
    }

    // MARK: - Bug 1: ambiguous layout (missing horizontal position)

    private func setupAmbiguous() {
        let box = makeBox(.systemBlue)
        view.addSubview(box)

        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            box.widthAnchor.constraint(equalToConstant: 120),
            box.heightAnchor.constraint(equalToConstant: 120),
            // 🐞 BUG: nothing pins the box horizontally → its X position is ambiguous.
            //         Run, pause, then in the console:
            //           po box.hasAmbiguousLayout        // → true
            //           expr -l objc++ -O -- [[UIWindow keyWindow] _autolayoutTrace]
            // ✅ FIX: give it a horizontal position, e.g.:
            // box.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - Bug 2: incorrect frame (forgot translatesAutoresizingMaskIntoConstraints)

    private func setupForgotTranslates() {
        let box = UIView()
        box.backgroundColor = .systemGreen
        box.layer.cornerRadius = 8
        // 🐞 BUG: this view still has translatesAutoresizingMaskIntoConstraints == true,
        //         so its autoresizing mask fights the constraints below. The console
        //         prints "Unable to simultaneously satisfy constraints" mentioning
        //         NSAutoresizingMaskLayoutConstraints.
        // ✅ FIX: uncomment the next line.
        // box.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(box)

        NSLayoutConstraint.activate([
            box.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            box.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            box.widthAnchor.constraint(equalToConstant: 120),
            box.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    // MARK: - Bug 3: overlapping / invisible view (z-order)

    private func setupOverlap() {
        let back = makeBox(.systemRed)
        let front = makeBox(.systemBlue)
        view.addSubview(back)
        view.addSubview(front)   // added last → drawn on top, covering `back`

        NSLayoutConstraint.activate([
            back.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            back.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            back.widthAnchor.constraint(equalToConstant: 180),
            back.heightAnchor.constraint(equalToConstant: 180),

            front.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            front.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            front.widthAnchor.constraint(equalToConstant: 180),
            front.heightAnchor.constraint(equalToConstant: 180),
        ])

        // 🐞 BUG: `back` (red) shares `front`'s (blue) frame and sits directly behind it,
        //         so it looks like the red box "disappeared." There is NO console warning.
        //         Open the Debug View Hierarchy and tilt to 3D to see both layers.
        // ✅ FIX (one option): offset `back` so both are visible, e.g. replace its
        //         center constraints with a shifted position, or bring it forward:
        // view.bringSubviewToFront(back)
    }

    // MARK: - Bug 4: unsatisfiable conflict (two contradictory required widths)

    private func setupConflict() {
        let box = makeBox(.systemPurple)
        view.addSubview(box)

        let width100 = box.widthAnchor.constraint(equalToConstant: 100)
        let width200 = box.widthAnchor.constraint(equalToConstant: 200)
        // Identifiers make the console log readable (see §3).
        width100.identifier = "box.width.100"
        width200.identifier = "box.width.200"

        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            box.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            box.heightAnchor.constraint(equalToConstant: 100),
            width100,
            width200,
            // 🐞 BUG: width can't be both 100 AND 200 (both required) → "Unable to
            //         simultaneously satisfy constraints." Catch it at the source with a
            //         symbolic breakpoint on UIViewAlertForUnsatisfiableConstraints (§5).
            // ✅ FIX: remove one width, or make one optional:
            // width200.priority = .defaultHigh
        ])
    }

    // MARK: - Bug 5: no warning at all — label truncates (numberOfLines == 1)

    private func setupSelfSizingTruncation() {
        let card = makeBox(.secondarySystemBackground)
        view.addSubview(card)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "This is a fairly long sentence that should wrap onto several lines, "
            + "but it silently truncates instead — and the console prints nothing."
        // 🐞 BUG: numberOfLines defaults to 1, so the text is cut off with "…".
        //         There is NO warning; you diagnose this by inspecting the label's
        //         frame in the view debugger and reasoning about it.
        // ✅ FIX: uncomment the next line.
        // label.numberOfLines = 0
        card.addSubview(label)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Helper

    private func makeBox(_ color: UIColor) -> UIView {
        let box = UIView()
        box.backgroundColor = color
        box.layer.cornerRadius = 8
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }
}
