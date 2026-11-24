import ArgumentParser
import agtermCore

// This fork's `session split command`, kept out of `Session.Split` so upstream's struct stays within its length.
extension Session.Split {
    /// Not `Command`, which would shadow agtermCore's protocol enum; `commandName` keeps the verb.
    struct NewSplitCommand: RequestCommand {
        static let configuration = CommandConfiguration(
            commandName: "command",
            abstract: "Set what every newly created split of the session runs (or --clear for a login shell).",
            discussion: """
                Applies when a split is created, by ⌘D or `session split`; showing a hidden split runs \
                nothing new. COMMAND runs as `session new --command` runs it: outside Live sessions a `;` or `&&` \
                list runs only its first command unless wrapped in `sh -c`. Persisted with the session and read back on \
                `tree` as newSplitCommand.
                """)
        @Argument(help: "The command a new split runs (omit with --clear).") var command: String?
        @Flag(name: .long, help: "Drop the command, so a new split is a login shell again.") var clear = false
        @OptionGroup var target: TargetOptions
        @OptionGroup var options: ClientOptions

        func validate() throws {
            guard (command != nil) != clear else {
                throw ValidationError("provide exactly one of a COMMAND or --clear")
            }
        }

        func makeRequest() throws -> ControlRequest {
            ControlRequest(cmd: .sessionSplitCommand, target: target.target,
                           args: options.withWindow(ControlArgs(mode: clear ? "clear" : "set", command: command)))
        }
    }
}
