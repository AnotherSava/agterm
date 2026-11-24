import AppKit
import XCTest
@testable import agterm
import agtermCore

@MainActor
final class ControlServerSplitCommandTests: XCTestCase {
    private var stateDir: URL!
    private var library: WindowLibrary!
    private var server: ControlServer!
    private var dispatcher: ControlDispatcher!

    override func setUp() async throws {
        try await super.setUp()
        stateDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("agterm-split-command-tests-\(UUID().uuidString)", isDirectory: true)
        library = WindowLibrary(directory: stateDir)
        let actions = AppActions(library: library)
        server = ControlServer(
            library: library,
            actions: actions,
            settingsModel: SettingsModel(library: library, settingsStore: SettingsStore(directory: stateDir)),
            identity: AppIdentity(version: "9.9.9", commit: "testsha"),
            socketPath: stateDir.appendingPathComponent("control.sock").path
        )
        dispatcher = ControlDispatcher(actions: server)
    }

    override func tearDown() async throws {
        dispatcher = nil
        server = nil
        library = nil
        try? FileManager.default.removeItem(at: stateDir)
        stateDir = nil
        try await super.tearDown()
    }

    private func addSession() throws -> (AppStore, Session) {
        let store = try XCTUnwrap(library.activeStore)
        let owner = try XCTUnwrap(store.currentWorkspaceID)
        return (store, try XCTUnwrap(store.addSession(toWorkspace: owner, cwd: NSHomeDirectory())))
    }

    private func send(_ cmd: Command, _ session: Session, _ args: ControlArgs) async -> ControlResponse? {
        await dispatcher.dispatch(ControlRequest(cmd: cmd, target: session.id.uuidString, args: args))
    }

    func testTheStoredCommandRunsInTheNextSplitAndReadsBack() async throws {
        let (store, session) = try addSession()

        let set = await send(.sessionSplitCommand, session, ControlArgs(mode: "set", command: "ssh -t box"))
        XCTAssertEqual(set?.ok, true, set?.error ?? "")
        let node = store.controlTree().workspaces.flatMap(\.sessions).first { $0.id == session.id.uuidString }
        XCTAssertEqual(node?.newSplitCommand, "ssh -t box")

        let split = await send(.sessionSplit, session, ControlArgs(mode: "on"))
        XCTAssertEqual(split?.ok, true, split?.error ?? "")
        XCTAssertEqual(session.splitInitialCommand, "ssh -t box")

        let cleared = await send(.sessionSplitCommand, session, ControlArgs(mode: "clear"))
        XCTAssertEqual(cleared?.ok, true)
        XCTAssertNil(session.newSplitCommand)
    }

    func testAOneOffCommandIsRefusedOnceTheSplitExists() async throws {
        let (_, session) = try addSession()

        let created = await send(.sessionSplit, session, ControlArgs(mode: "on", command: "htop"))
        XCTAssertEqual(created?.ok, true, created?.error ?? "")
        XCTAssertEqual(session.splitInitialCommand, "htop")

        _ = await send(.sessionSplit, session, ControlArgs(mode: "off"))
        let again = await send(.sessionSplit, session, ControlArgs(mode: "toggle", command: "top"))
        XCTAssertEqual(again?.ok, false)
        XCTAssertFalse(session.isSplit)
        XCTAssertEqual(session.splitInitialCommand, "htop")
    }

    func testSplitCommandsAreRefusedOnARemoteRow() throws {
        let store = try XCTUnwrap(library.activeStore)
        let owner = try XCTUnwrap(store.currentWorkspaceID)
        let row = try XCTUnwrap(store.addSession(toWorkspace: owner, cwd: NSHomeDirectory(), remoteHost: "buildbox"))
        let requests = [
            ControlRequest(cmd: .sessionSplitCommand, target: row.id.uuidString, args: ControlArgs(mode: "set", command: "htop")),
            ControlRequest(cmd: .sessionSplit, target: row.id.uuidString, args: ControlArgs(mode: "on", command: "htop")),
        ]
        for request in requests {
            guard case .refused(let response) = server.remoteRoute(request) else {
                return XCTFail("\(request.cmd.rawValue) was not refused")
            }
            XCTAssertEqual(response.error, "split commands apply only to local sessions")
        }
        XCTAssertNil(row.newSplitCommand)
    }
}
