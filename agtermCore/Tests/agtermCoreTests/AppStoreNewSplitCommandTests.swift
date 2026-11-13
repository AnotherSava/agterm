import Foundation
import Testing
@testable import agtermCore

@MainActor
struct AppStoreNewSplitCommandTests {
    @Test func aCreatedSplitRunsTheSessionsCommand() throws {
        let store = makeStore()
        let session = try #require(store.addSession(toWorkspace: store.addWorkspace(name: "w").id, cwd: "/tmp"))
        #expect(store.setNewSplitCommand("ssh -t box", forSession: session.id))

        store.toggleSplit(session.id)

        #expect(session.splitInitialCommand == "ssh -t box")
    }

    @Test func reshowingAHiddenSplitKeepsItsOwnCommand() throws {
        let store = makeStore()
        let session = try #require(store.addSession(toWorkspace: store.addWorkspace(name: "w").id, cwd: "/tmp"))
        store.toggleSplit(session.id)
        store.toggleSplit(session.id)
        store.setNewSplitCommand("ssh -t box", forSession: session.id)

        store.toggleSplit(session.id)

        #expect(session.isSplit)
        #expect(session.splitInitialCommand == nil)
    }

    @Test func anExplicitCommandWinsAndClosingTheSplitForgetsIt() throws {
        let store = makeStore()
        let session = try #require(store.addSession(toWorkspace: store.addWorkspace(name: "w").id, cwd: "/tmp"))
        store.setNewSplitCommand("ssh -t box", forSession: session.id)

        store.setSplitVisibility(session.id, shown: true, command: "htop")
        #expect(session.splitInitialCommand == "htop")

        store.closeSplit(session.id)
        store.toggleSplit(session.id)
        #expect(session.splitInitialCommand == "ssh -t box")
    }

    @Test func clearingRestoresAPlainShell() throws {
        let store = makeStore()
        let session = try #require(store.addSession(toWorkspace: store.addWorkspace(name: "w").id, cwd: "/tmp"))
        store.setNewSplitCommand("ssh -t box", forSession: session.id)
        store.setNewSplitCommand(nil, forSession: session.id)

        store.toggleSplit(session.id)

        #expect(session.splitInitialCommand == nil)
        #expect(!store.setNewSplitCommand("x", forSession: UUID()))
    }

    @Test func onlyASplitThatExistedAtRestoreCountsAsRestored() throws {
        let store = makeStore()
        let workspace = store.addWorkspace(name: "w")
        _ = try #require(store.addSession(toWorkspace: workspace.id, cwd: "/a"))
        let split = try #require(store.addSession(toWorkspace: workspace.id, cwd: "/b"))
        store.toggleSplit(split.id)
        let restored = makeStore()
        restored.restore(from: store.snapshot())
        let sessions = restored.workspaces.flatMap(\.sessions)
        let plain = try #require(sessions.first { !$0.hasSplit })
        let withSplit = try #require(sessions.first { $0.hasSplit })

        #expect(withSplit.paneWasRestored(.right))
        #expect(plain.paneWasRestored(.left) && !plain.paneWasRestored(.right))

        restored.toggleSplit(plain.id)
        #expect(!plain.paneWasRestored(.right))
    }

    @Test func theCommandSurvivesARestoreAndReadsBackOnTheTree() throws {
        let store = makeStore()
        let session = try #require(store.addSession(toWorkspace: store.addWorkspace(name: "w").id, cwd: "/tmp"))
        store.setNewSplitCommand("ssh -t box", forSession: session.id)
        let restored = makeStore()

        restored.restore(from: store.snapshot())

        #expect(restored.workspaces.flatMap(\.sessions).first?.newSplitCommand == "ssh -t box")
        #expect(restored.controlTree().workspaces[0].sessions[0].newSplitCommand == "ssh -t box")
    }
}
