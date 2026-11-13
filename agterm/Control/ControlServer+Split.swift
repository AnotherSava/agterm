import agtermCore
import Foundation

extension ControlServer {
    func splitSession(_ target: String?, window: String?, mode: String?, axis: SplitAxis?,
                      command: String?) -> ControlResponse {
        splitSession(target, window: window, mode: mode, axis: axis, focus: true, command: command)
    }

    func setSessionNewSplitCommand(_ target: String?, window: String?, command: String?) -> ControlResponse {
        return resolver.resolveSession(target, window: window) { store, id in
            guard store.setNewSplitCommand(command, forSession: id) else {
                return ControlResponse(ok: false, error: "no such session: \(target ?? "active")")
            }
            return ControlResponse(ok: true, result: ControlResult(id: id.uuidString))
        }
    }

    /// A remote row's split is created on its host, which neither forwards nor stores a split command, so the
    /// command would silently never run. Checked ahead of `remoteRoute`'s forwarding.
    func splitCommandRemoteRefusal(_ request: ControlRequest) -> RemoteRoute? {
        let carriesCommand = request.cmd == .sessionSplitCommand || (request.cmd == .sessionSplit && request.args?.command != nil)
        guard carriesCommand,
              case .success(let (store, id)) = resolver.resolveSessionTarget(request.target, window: request.args?.window),
              store.session(withID: id)?.remoteHost != nil else { return nil }
        return .refused(ControlResponse(ok: false, error: "split commands apply only to local sessions"))
    }
}
