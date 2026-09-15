import XCTest

final class SomnusUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-hasCompletedOnboarding", "YES"
        ]
        app.launch()
    }

    func testPrimaryNavigationAndReleaseInformation() {
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts["Error"].exists)

        app.tabBars.buttons["Trends"].tap()
        XCTAssertTrue(app.navigationBars["Trends"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.alerts["Error"].exists)
        XCTAssertTrue(app.buttons["1D"].exists)
        XCTAssertTrue(app.buttons["1W"].exists)
        XCTAssertTrue(app.buttons["1M"].exists)
        XCTAssertTrue(app.buttons["1Y"].exists)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["How Sleep Data Works"].waitForExistence(timeout: 3))

        app.swipeUp()
        XCTAssertTrue(app.buttons["How Sleep Score Is Calculated"].waitForExistence(timeout: 3))
        app.buttons["How Sleep Score Is Calculated"].tap()
        XCTAssertTrue(app.navigationBars["Sleep Score"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["What the Score Means"].exists)
        XCTAssertTrue(app.staticTexts["Weighted Components"].exists)

        app.navigationBars.buttons["Settings"].tap()
        app.swipeDown()
        XCTAssertTrue(app.buttons["Privacy Policy"].waitForExistence(timeout: 3))
        app.buttons["Privacy Policy"].tap()
        XCTAssertTrue(app.navigationBars["Privacy Policy"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Data Somnus Accesses"].exists)
        XCTAssertTrue(app.staticTexts["Storage and Retention"].exists)
    }
}
