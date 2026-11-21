// SPDX-License-Identifier: Apache-2.0
import XCTest
@testable import simless

/// Render lanes: more render hosts of one worktree, each its own slot of the same build (`simless start --lane N`).
final class LaneTests: XCTestCase {
    func testLaneKinds() {
        XCTAssertNil(SlotRecord.laneKind(1), "lane 1 is the worktree's render host")
        XCTAssertNil(SlotRecord.laneKind(0))
        XCTAssertEqual(SlotRecord.laneKind(2), "lane2")
        XCTAssertEqual(SlotRecord.laneNumber("lane12"), 12)
        XCTAssertNil(SlotRecord.laneNumber("lane1"), "lane 1 has no kind")
        XCTAssertNil(SlotRecord.laneNumber("lanex"))
        XCTAssertNil(SlotRecord.laneNumber("test"))
        XCTAssertNil(SlotRecord.laneNumber(nil))
    }

    func testRenderHostsAreTheWorktreesAndItsLanes() {
        var slot = SlotRecord(bundleBase: "com.example.app", n: 1, worktree: "/w", port: 47800)
        XCTAssertTrue(slot.isRenderHost)
        slot.kind = "lane3"
        XCTAssertTrue(slot.isRenderHost)
        XCTAssertEqual(slot.slotID, "com.example.app.simless1-lane3")
        for kind in ["test", "ui1", "ui2"] {
            slot.kind = kind
            XCTAssertFalse(slot.isRenderHost, kind)
        }
    }
}
