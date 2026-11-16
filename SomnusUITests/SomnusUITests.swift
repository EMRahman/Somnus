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

    func testWeekdayDebtAcrossLongRanges() {
        app.terminate()
        app.launchArguments += ["-screenshotMode", "-screenshotDestination=monthly-duration"]
        app.launch()

        XCTAssertTrue(app.buttons["By weekday"].waitForExistence(timeout: 5))
        app.buttons["By weekday"].tap()
        XCTAssertTrue(app.buttons["weekday-debt-2"].waitForExistence(timeout: 3))
        let summary = app.descendants(matching: .any)["weekday-debt-summary"]
        XCTAssertTrue(summary.label.contains("Monday"))
        XCTAssertTrue(summary.label.contains("recorded nights"))
        app.buttons["weekday-debt-3"].tap()
        XCTAssertTrue(summary.label.contains("Tuesday"))
        attachScreenshot("Monthly weekday debt")

        for period in ["1Y", "5Y", "10Y"] {
            app.buttons[period].tap()
            XCTAssertTrue(app.buttons["weekday-debt-2"].waitForExistence(timeout: 5))
            app.buttons["weekday-debt-2"].tap()
            XCTAssertTrue(summary.label.contains("Monday"))
            XCTAssertTrue(app.staticTexts[period == "1Y" ? "Monthly averages" : "Yearly averages"].exists)
            attachScreenshot("\(period) weekday debt")
        }

        app.buttons["By time"].tap()
        XCTAssertFalse(app.buttons["weekday-debt-2"].exists)
        XCTAssertTrue(app.staticTexts["Cumulative debt"].exists)

        app.buttons["1W"].tap()
        XCTAssertFalse(app.buttons["By weekday"].exists)
        XCTAssertTrue(app.staticTexts["Cumulative debt"].exists)
        app.buttons["1D"].tap()
        XCTAssertFalse(app.buttons["By weekday"].exists)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
