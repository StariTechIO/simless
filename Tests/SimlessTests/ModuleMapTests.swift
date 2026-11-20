// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Abacus.AI, Inc.

import XCTest
@testable import simless

final class ModuleMapTests: XCTestCase {
    func testTopLevelNamesOnly() {
        let text = """
            framework module PostHog {
              umbrella header "PostHog.h"
              explicit module Private { header "P.h" }
              export *
            }
            module phlibwebp {
              umbrella "../../../vendor/libwebp"
            }
            extern module Elsewhere "../Elsewhere/module.modulemap"
            """
        XCTAssertEqual(Patch.moduleNames(in: text), ["PostHog", "phlibwebp"])
    }

    /// posthog-ios ships PrivateModules/<C target>/module.modulemap beside the map
    /// SwiftPM generates for the same target; passing both is "redefinition of module".
    func testALaterMapDefiningTheSameModuleIsLeftOut() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("simless-modulemaps-\(UUID().uuidString)").path
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        func map(_ name: String, _ text: String) throws -> String {
            let path = "\(dir)/\(name).modulemap"
            try text.write(toFile: path, atomically: true, encoding: .utf8)
            return path
        }
        let generated = try map("generated-phlibwebp", "module phlibwebp {\numbrella \"/x/vendor/libwebp\"\nexport *\n}\n")
        let other = try map("generated-PostHog", "module PostHog {\nheader \"PostHog-Swift.h\"\n}\n")
        let checkout = try map("checkout-phlibwebp", "module phlibwebp {\n  umbrella \"../../../vendor/libwebp\"\n  export *\n}\n")
        let unrelated = try map("checkout-CZlib", "module CZlib [system] {\n  link \"z\"\n}\n")
        XCTAssertEqual(Patch.firstDefinitions([generated, other, checkout, unrelated]), [generated, other, unrelated])
    }
}
