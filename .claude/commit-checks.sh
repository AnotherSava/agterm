#!/usr/bin/env bash
# What /commit runs before it will draft a commit plan in this fork. Upstream carries no gate of its
# own, and this clone commits straight to master, so nothing else reads a change here on its way in.
#
# Runs, in this order:
#   the conventions checker — every rule this repo's `.claude/conventions` number entitles it to,
#     plus the universal ones. Nothing else invokes it, so without this line each rule would be
#     measured once, by the /adopt walk on the day it ran, and never again.
#   `make lint`   — `swiftlint lint --strict --quiet`, CI's lint job plus `--quiet`, which drops
#     progress output and no findings. Seconds.
#   `make test`   — the host-free agtermCore suite, CI's test job minus the coverage export.
#
# Deliberately absent, with the reason, because a gate trusted for more than it checks is the thing
# this file is most likely to become:
#   `scripts/test-app.sh` — it rebuilds the Debug bundle a running instance launched from, which
#     replaces a live app's signed image on disk, and CLAUDE.md records the runner timing out at
#     init when started from a shell inside a live agterm pane. A gate that fails for reasons
#     unrelated to the diff stops being read. Run it by hand before pushing anything that touches
#     AppKit or the control server.
#   `scripts/build.sh` — the Release build is the honest type check, and CLAUDE.md names a class of
#     failure only it catches: Darwin Foundation CG types that pass Debug and tests and crash Xcode's
#     Release WMO deserialization. It costs minutes per commit, so it is left to CI's build job.
#     A green run here therefore does not say the app compiles under Release.
#   the helper signature and entitlement verifications, and the whole cookbook job — CI only.
#
# Prerequisites are `python3`, `swiftlint` and Xcode's `swift` on PATH. Each absence fails rather
# than skips: a check that cannot tell "passed" from "never ran" turns an open problem into a
# closed-looking one.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

status=0

# Buffer each step and print its detail only when it fails, so a wall of output at every commit does
# not train the reader to skip it. The tally line always shows, because a silent pass is the other
# failure mode.
run() {
  local label="$1" out
  shift
  out="$(mktemp)"
  if "$@" >"$out" 2>&1; then
    echo "==> $label — $(tail -n 1 "$out")"
  else
    echo "==> $label — FAILED"
    cat "$out"
    status=1
  fi
  rm -f "$out"
}

# First, so a convention violation is reported before anything slower runs. Reached through the
# installed path because only the dotfiles repo holds `claude/conventions/` inside it.
run "Conventions — this repo" python3 "$HOME/.claude/conventions/check.py" .
run "swiftlint --strict" make lint
run "agtermCore tests" make test

exit "$status"
