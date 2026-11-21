// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Abacus.AI, Inc.

import XCTest
@testable import simless

/// Each worktree builds with its own compilation cache: one cache shared by builds running side by side crashed Xcode's
/// build service in the cache's memory-mapped store ("The Xcode build system has crashed").
final class CompilationCacheTests: XCTestCase {
    private func workspace(_ name: String) -> Workspace {
        Workspace(root: NSTemporaryDirectory() + "simless-cas-\(name)-" + UUID().uuidString,
                  config: Config(project: "App.xcodeproj", scheme: "App", appTarget: "App", testTarget: "AppTests", kitDir: "App/Simless", sourceDirs: ["App"]))
    }

    func testEachWorktreeBuildsWithItsOwnCacheInItsBuildFolder() {
        let a = workspace("a"), b = workspace("b")
        XCTAssertNotEqual(a.compilationCache, b.compilationCache)
        XCTAssertTrue(a.compilationCache.hasPrefix(a.work + "/"))
        XCTAssertEqual(a.buildSettings.filter { $0.hasPrefix("COMPILATION_CACHE_CAS_PATH=") }, ["COMPILATION_CACHE_CAS_PATH=\(a.compilationCache)"])
        XCTAssertTrue(a.buildSettings.contains("COMPILATION_CACHE_ENABLE_CACHING=YES"))
        XCTAssertFalse(Workspace.sharedSettings.contains { $0.hasPrefix("COMPILATION_CACHE_CAS_PATH=") }, "no cache path is shared by every worktree")
    }

    func testAPoisonedCacheClearsOnlyThatWorktreesCache() throws {
        let dir = NSTemporaryDirectory() + "simless-cas-" + UUID().uuidString
        let mine = "\(dir)/mine/CompilationCache", other = "\(dir)/other/CompilationCache"
        for d in [mine, other] { try FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true) }
        defer { try? FileManager.default.removeItem(atPath: dir) }
        var builds = 0
        let r = Cleanup.retryingPoisonedCache(mine) { () -> Shell.Result in
            builds += 1
            return builds == 1 ? Shell.Result(code: 65, out: "error: compilation cache poisoned") : Shell.Result(code: 0, out: "")
        }
        XCTAssertEqual(r.code, 0)
        XCTAssertEqual(builds, 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: mine))
        XCTAssertTrue(FileManager.default.fileExists(atPath: other), "another worktree's cache is never touched")
    }
}
