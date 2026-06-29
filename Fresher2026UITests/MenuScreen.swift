//
//  MenuScreen.swift
//  Fresher2026UITests   ← UI TEST target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 4 — a Page Object for the root menu. Tests speak intent ("open Components");
//  the queries live here, so a UI change is fixed in one place.
//

import XCTest

struct MenuScreen {
    let app: XCUIApplication

    /// True once the menu has appeared (the first item exists).
    var isVisible: Bool {
        app.buttons["Components"].waitForExistence(timeout: 2)
    }

    /// Tap a menu item by its title. (Switch to accessibility identifiers in Lab 2.)
    @discardableResult
    func open(_ title: String) -> MenuScreen {
        app.buttons[title].tap()
        return self
    }

    /// The navigation back button (the root screen's title is "Demo").
    var backButton: XCUIElement {
        app.navigationBars.buttons["Demo"]
    }
}
