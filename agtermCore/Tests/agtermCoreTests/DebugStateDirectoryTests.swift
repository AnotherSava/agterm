import Foundation
import Testing
@testable import agtermCore

struct DebugStateDirectoryTests {
    static let live = URL(fileURLWithPath: "/Users/me/Library/Application Support/agterm", isDirectory: true)

    @Test func anUnisolatedLaunchAdoptsASiblingOfTheLiveDirectory() {
        #expect(DebugStateDirectory.adopted(environment: [:], liveDirectory: Self.live)
            == "/Users/me/Library/Application Support/agterm-debug")
        #expect(DebugStateDirectory.adopted(environment: ["AGTERM_STATE_DIR": ""], liveDirectory: Self.live)
            == "/Users/me/Library/Application Support/agterm-debug")
    }

    @Test func anExplicitDirectoryIsKeptEvenWhenItIsTheLiveOne() {
        #expect(DebugStateDirectory.adopted(environment: ["AGTERM_STATE_DIR": "/tmp/s"], liveDirectory: Self.live) == nil)
        #expect(DebugStateDirectory.adopted(environment: ["AGTERM_STATE_DIR": Self.live.path],
                                            liveDirectory: Self.live) == nil)
    }

    @Test func theAdoptedSocketPathFitsTheUnixSocketLimit() throws {
        let home = URL(fileURLWithPath: "/Users/averagelongusername/Library/Application Support/agterm", isDirectory: true)
        let adopted = try #require(DebugStateDirectory.adopted(environment: [:], liveDirectory: home))
        #expect(ControlResolve.socketPath(stateDir: adopted, appSupport: home.path).utf8.count < 104)
    }
}
