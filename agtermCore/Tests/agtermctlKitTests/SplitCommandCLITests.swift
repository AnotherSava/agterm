import ArgumentParser
import Foundation
import Testing
import agtermCore
@testable import agtermctlKit

struct SplitCommandCLITests {
    private func request(_ argv: [String]) throws -> ControlRequest {
        let parsed = try Agtermctl.parseAsRoot(argv)
        guard let command = parsed as? any RequestCommand else {
            throw SocketClientError("parsed \(argv) is not a RequestCommand")
        }
        return try command.makeRequest()
    }

    private func validationMessage(_ argv: [String]) -> String? {
        do {
            _ = try Agtermctl.parseAsRoot(argv)
            return nil
        } catch {
            return Agtermctl.message(for: error)
        }
    }

    @Test func sessionSplitOnWithCommand() throws {
        let expected = ControlRequest(cmd: .sessionSplit, target: "active", args: ControlArgs(mode: "on", command: "ssh -t box"))
        #expect(try request(["session", "split", "on", "--command", "ssh -t box"]) == expected)
        #expect(validationMessage(["session", "split", "off", "--command", "htop"])
            == "--command needs a mode that shows the split (on or toggle)")
    }

    @Test func sessionSplitCommandSetAndClear() throws {
        let set = ControlRequest(cmd: .sessionSplitCommand, target: "s1",
                                 args: ControlArgs(mode: "set", command: "ssh -t box", window: "w1"))
        #expect(try request(["session", "split", "command", "ssh -t box", "--target", "s1", "--window", "w1"]) == set)
        #expect(try request(["session", "split", "command", "--clear"])
            == ControlRequest(cmd: .sessionSplitCommand, target: "active", args: ControlArgs(mode: "clear")))
        #expect(validationMessage(["session", "split", "command"]) == "provide exactly one of a COMMAND or --clear")
        #expect(validationMessage(["session", "split", "command", "x", "--clear"]) == "provide exactly one of a COMMAND or --clear")
    }
}
