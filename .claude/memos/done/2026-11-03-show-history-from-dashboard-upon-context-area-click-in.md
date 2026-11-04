---
created: 2026-10-14 10:13:42
---

# show history from dashboard upon context area click in agterm

Plan from the 2026-11-03 discussion: show the dashboard's history for an agent as a page in the right pane of a split on that agent's session, so the agent stays visible on the left.

```
agtermctl session split on --target "$AGT_SESSION_ID"
agtermctl session overlay open --url "http://127.0.0.1:<dashboard-port>/<history-route>" --chromeless --persistent --pane right --target "$AGT_SESSION_ID"
```

- Trigger: the context text in agterm's title bar has no click handler, so the click the title asks for needs an upstream change. Until then, use a `command` line in `~/.config/agterm/keymap.conf` with a chord, passing `{AGT_SESSION_ID}`, or a button in the dashboard.
- The dashboard must map the agterm session id to its row. That is the agterm-ids proposal sent to the tauri-dashboard session on 2026-11-03 (`AGTERM_SESSION_ID` in each hook event body).
- `--chromeless` is allowed only for a loopback host, which the dashboard's server is.
- Closing the page leaves a plain shell in the right pane, so the command should also close the split (`agtermctl session split close`), or the toggle should close both together.
- A pane overlay is refused when the right pane already holds one (`pane overlay already open`), and when the split is hidden (`pane not visible`).
- Rejected: a companion session. It is a separate tab rather than side by side, and it makes the agent's shell respawn instead of closing when Claude exits. The dashboard's window walk, restore and idle close would also all have to skip it.
- Unverified: neither command has been run, and the history route does not exist in the dashboard yet.

Not implemented here: closed on 2026-11-03 because all of the work is in tauri-dashboard, which carries it as its memo "show an agent's dashboard history in the right pane of a split".
