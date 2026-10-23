import AppKit
import XCTest
@testable import PopDeck

final class PanelFocusRecoveryTests: XCTestCase {
    @MainActor
    func testActivationAfterPresentationRepairsFocusAndRefreshesHover() {
        let center = NotificationCenter()
        var pending: [HaloPanelFocusRecovery.Operation] = []
        let recovery = HaloPanelFocusRecovery(center: center, schedule: { pending.append($0) })
        defer { recovery.cancel() }
        var appActive = false
        var key = false
        var hoverRefreshes = 0
        recovery.begin(isCurrent: { true }, repair: {
            if appActive { key = true }
            hoverRefreshes += 1
        })
        XCTAssertEqual(pending.count, 1)
        pending.removeFirst()()
        XCTAssertFalse(key)
        XCTAssertEqual(hoverRefreshes, 1)
        appActive = true
        center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(pending.count, 1)
        pending.removeFirst()()
        XCTAssertTrue(key)
        XCTAssertEqual(hoverRefreshes, 2)
    }

    @MainActor
    func testDismissBeforeDelayedActivationNeverReopensOrStealsFocus() {
        let center = NotificationCenter()
        var pending: [HaloPanelFocusRecovery.Operation] = []
        let recovery = HaloPanelFocusRecovery(center: center, schedule: { pending.append($0) })
        var repairs = 0
        recovery.begin(isCurrent: { true }, repair: { repairs += 1 })
        let delayed = pending.removeFirst()
        recovery.cancel()
        delayed()
        center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(repairs, 0)
        XCTAssertTrue(pending.isEmpty)
    }

    @MainActor
    func testOldQueuedWorkCannotAffectAReopenedPresentation() {
        let center = NotificationCenter()
        var pending: [HaloPanelFocusRecovery.Operation] = []
        let recovery = HaloPanelFocusRecovery(center: center, schedule: { pending.append($0) })
        defer { recovery.cancel() }
        var repaired: [Int] = []
        recovery.begin(isCurrent: { true }, repair: { repaired.append(1) })
        let old = pending.removeFirst()
        recovery.begin(isCurrent: { true }, repair: { repaired.append(2) })
        old()
        center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(pending.count, 1)
        pending.removeFirst()()
        XCTAssertEqual(repaired, [2])
    }

    @MainActor
    func testNoLongerVisiblePresentationUnsubscribesWithoutRepair() {
        let center = NotificationCenter()
        var pending: [HaloPanelFocusRecovery.Operation] = []
        let recovery = HaloPanelFocusRecovery(center: center, schedule: { pending.append($0) })
        var visible = true
        var repairs = 0
        recovery.begin(isCurrent: { visible }, repair: { repairs += 1 })
        visible = false
        pending.removeFirst()()
        center.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(repairs, 0)
        XCTAssertTrue(pending.isEmpty)
    }
}
