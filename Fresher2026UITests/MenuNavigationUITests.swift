//
//  MenuNavigationUITests.swift
//  Fresher2026UITests   ← UI TEST target
//
//  Created by TaiTQ2 on 24/6/26.
//
//  Module 4 — a UI test driving a real navigation flow, using a Page Object and
//  waiting for elements (never sleeping).
//

import XCTest

final class MenuNavigationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false      // a failed step makes later steps meaningless
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]   // app can read this to use stub data
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_openComponents_pushesScreen_andCanGoBack() {
        let menu = MenuScreen(app: app)

        // Arrange — menu is on screen
        XCTAssertTrue(menu.isVisible, "Menu should be visible on launch")

        // Act — open a demo
        menu.open("Components")

        // Assert — we navigated (a back button appears), then return
        XCTAssertTrue(menu.backButton.waitForExistence(timeout: 2),
                      "Tapping a menu item should push a screen with a back button")
        menu.backButton.tap()

        // Assert — back on the menu
        XCTAssertTrue(app.buttons["Components"].waitForExistence(timeout: 2),
                      "Going back should return to the menu")
    }
}
