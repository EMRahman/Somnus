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
        XCTAssertTrue(app.descendants(matching: .any)["Review Somnus"].firstMatch.waitForExistence(timeout: 3))
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

    func testByTimeChartSelection() {
        relaunchForScreenshot(destination: "debt")

        let debtChart = app.descendants(matching: .any)["debt-time-chart"].firstMatch
        XCTAssertTrue(debtChart.waitForExistence(timeout: 5))
        scrollIntoView(debtChart)
        debtChart.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()

        let debtSummary = app.descendants(matching: .any)["debt-time-selection-summary"].firstMatch
        XCTAssertTrue(debtSummary.waitForExistence(timeout: 3))

        let timelineChart = app.descendants(matching: .any)["sleep-timeline-chart"].firstMatch
        XCTAssertTrue(timelineChart.waitForExistence(timeout: 5))
        scrollIntoView(timelineChart)
        timelineChart.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5)).tap()

        let timelineSummary = app.descendants(matching: .any)["timeline-selection-summary"].firstMatch
        XCTAssertTrue(timelineSummary.waitForExistence(timeout: 3))
        XCTAssertTrue(timelineSummary.label.contains("asleep"))

        let yearButton = app.buttons["1Y"]
        scrollIntoView(yearButton)
        yearButton.tap()

        XCTAssertTrue(debtChart.waitForExistence(timeout: 5))
        scrollIntoView(debtChart)
        debtChart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(debtSummary.waitForExistence(timeout: 3))
        XCTAssertTrue(debtSummary.label.contains("recorded"))
        app.buttons["Clear selection"].firstMatch.tap()
        XCTAssertFalse(debtSummary.exists)

        let durationChart = app.descendants(matching: .any)["duration-averaged-chart"].firstMatch
        XCTAssertTrue(durationChart.waitForExistence(timeout: 5))
        scrollIntoView(durationChart)
        durationChart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let durationSummary = app.descendants(matching: .any)["duration-selection-summary"].firstMatch
        XCTAssertTrue(durationSummary.waitForExistence(timeout: 3))
        XCTAssertTrue(durationSummary.label.contains("average"))

        app.buttons["Clear selection"].firstMatch.tap()
        XCTAssertFalse(durationSummary.exists)
    }

    private func scrollIntoView(_ element: XCUIElement) {
        let window = app.windows.firstMatch
        let visibleTop = window.frame.minY + window.frame.height * 0.16
        let visibleBottom = window.frame.maxY - window.frame.height * 0.14
        for _ in 0..<6 {
            let frame = element.frame
            if element.isHittable && frame.midY >= visibleTop && frame.midY <= visibleBottom {
                return
            }
            let dy = frame.midY > visibleBottom ? -window.frame.height * 0.35 : window.frame.height * 0.35
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: 0, dy: dy))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
    }

    /// Captures the full App Store screenshot set (01–05) plus the monthly By time view used by
    /// the marketing website, all from the DEBUG-only synthetic fixture. Skipped unless run with
    /// TEST_RUNNER_SOMNUS_CAPTURE_SCREENSHOTS=1.
    func testCaptureAppStoreScreenshots() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SOMNUS_CAPTURE_SCREENSHOTS"] == "1")

        relaunchForScreenshot(destination: "dashboard")
        // iPad presents tabs outside `tabBars`, so match the tab button anywhere.
        XCTAssertTrue(app.buttons["Dashboard"].firstMatch.waitForExistence(timeout: 5))
        sleep(2)
        attachScreenshot("01-dashboard")

        relaunchForScreenshot(destination: "debt")
        XCTAssertTrue(app.staticTexts["Cumulative debt"].waitForExistence(timeout: 5))
        sleep(1)
        attachScreenshot("02-sleep-debt")

        relaunchForScreenshot(destination: "duration")
        XCTAssertTrue(app.staticTexts["Sleep Duration"].waitForExistence(timeout: 5))
        sleep(2)
        attachScreenshot("03-sleep-duration")

        relaunchForScreenshot(destination: "monthly-duration")
        XCTAssertTrue(app.staticTexts["Cumulative debt"].waitForExistence(timeout: 5))
        sleep(1)
        attachScreenshot("web-debt-month")

        relaunchForScreenshot(destination: "monthly-duration", extraArguments: ["-screenshotWeekdayDebt"])
        let monday = app.buttons["weekday-debt-2"]
        XCTAssertTrue(monday.waitForExistence(timeout: 5))
        scrollSleepDebtIntoView()
        attachScreenshot("04-weekday-month")

        app.buttons["1Y"].tap()
        XCTAssertTrue(monday.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Monthly averages"].waitForExistence(timeout: 5))
        scrollSleepDebtIntoView()
        attachScreenshot("05-weekday-year")
    }

    /// When the Sleep Debt card is cut off (compact iPhone layouts), scrolls until its heading
    /// sits just below the collapsed navigation bar. Larger screens are left unscrolled.
    private func scrollSleepDebtIntoView() {
        let heading = app.staticTexts["Sleep Debt"]
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        let footnote = app.staticTexts.containing(
            NSPredicate(format: "label BEGINSWITH %@", "Nights are labelled")
        ).firstMatch
        let window = app.windows.firstMatch
        let visibleBottom = window.frame.maxY - window.frame.height * 0.1
        guard !footnote.exists || footnote.frame.maxY > visibleBottom else { return }
        let targetY = window.frame.minY + window.frame.height * 0.15
        for _ in 0..<6 where heading.frame.minY > targetY + 20 {
            let distance = min(heading.frame.minY - targetY, window.frame.height * 0.5)
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            let end = start.withOffset(CGVector(dx: 0, dy: -distance))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        sleep(1)
    }

    private func relaunchForScreenshot(destination: String, extraArguments: [String] = []) {
        app.terminate()
        app.launchArguments = ["-hasCompletedOnboarding", "YES", "-screenshotMode",
                               "-screenshotDestination=\(destination)"] + extraArguments
        app.launch()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
