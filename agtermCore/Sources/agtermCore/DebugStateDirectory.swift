import Foundation

/// DebugStateDirectory keeps a Debug build off the deployed app's state when nothing isolates the launch.
public enum DebugStateDirectory {
    public static let environmentKey = "AGTERM_STATE_DIR"

    /// adopted returns a sibling of `liveDirectory`, nil when the launch names a non-empty directory.
    public static func adopted(environment: [String: String], liveDirectory: URL) -> String? {
        if let explicit = environment[environmentKey], !explicit.isEmpty { return nil }
        return liveDirectory.deletingLastPathComponent().appendingPathComponent("agterm-debug", isDirectory: true).path
    }
}
