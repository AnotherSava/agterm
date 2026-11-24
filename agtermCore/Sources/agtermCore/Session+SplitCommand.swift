/// SessionSplitCommand is this fork's `session.split.command` state, held in one stored `Session.forkSplit` so
/// upstream's `Session` stays within its length and a sync conflicts on one line.
public struct SessionSplitCommand: Sendable, Equatable {
    /// What every NEWLY created split runs, copied into `splitInitialCommand` at creation; re-showing a hidden
    /// split runs nothing new. Session-scoped, so a swap leaves it in place. Persisted: a Live relaunch
    /// re-attaches a tab without re-running whatever set it.
    public var command: String?
    /// `wasRestored` for the split pane: false for a split created after launch, which is a runtime pane even
    /// in a restored session and so runs its creation command. Never persisted.
    public var splitWasRestored = false
}

extension Session {
    public var newSplitCommand: String? {
        get { forkSplit.command }
        set { forkSplit.command = newValue }
    }

    public var splitWasRestored: Bool {
        get { forkSplit.splitWasRestored }
        set { forkSplit.splitWasRestored = newValue }
    }

    /// Whether `pane` came from a restore rather than being created this run.
    public func paneWasRestored(_ pane: StatusPane) -> Bool {
        pane == .right ? splitWasRestored : wasRestored
    }
}
