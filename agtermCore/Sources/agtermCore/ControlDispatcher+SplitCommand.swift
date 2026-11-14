import Foundation

extension ControlDispatcher {
    /// `session.split.command`: `set` stores the command every newly created split runs, `clear` drops it.
    func dispatchSplitCommand(_ request: ControlRequest) -> ControlResponse {
        let args = request.args
        switch args?.mode ?? "" {
        case "set":
            guard let command = args?.command else {
                return ControlResponse(ok: false, error: "session.split.command set requires a command")
            }
            if let rejection = Self.splitCommandRejection(command) { return rejection }
            return actions.setSessionNewSplitCommand(request.target, window: args?.window, command: command)
        case "clear":
            return actions.setSessionNewSplitCommand(request.target, window: args?.window, command: nil)
        default:
            return ControlResponse(ok: false,
                                   error: "invalid split command mode: \(args?.mode ?? "") (set|clear)")
        }
    }

    /// The command is stored, persisted and echoed by `tree`, so it gets the restore pin's limits.
    static func splitCommandRejection(_ command: String) -> ControlResponse? {
        commandRejection(command, maxBytes: ControlRestoreOverride.maxCommandBytes, emptyError: "command must not be empty")
            .map { ControlResponse(ok: false, error: $0.message) }
    }
}
