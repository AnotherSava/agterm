---
name: fork-and-local-install
description: This clone is a fork whose daily-driver app is a local ad-hoc build at /Applications, not the Homebrew cask
metadata:
  type: project
---

This checkout is a fork, and the agterm running on this machine is built from it rather than
installed from Homebrew. What follows is what neither the code nor git history records.

**Remotes are inverted from the usual fork layout on purpose.** `origin` is the user's fork,
`upstream` is `umputun/agterm`, and `master` tracks `upstream/master`. `remote.pushDefault` is
`origin`, so a bare `git push` reaches the fork and cannot reach upstream even by accident. Remotes
are not committed, so a second clone of this fork starts with neither of them until they are added by
hand, and behaves as a plain third-party clone until then.

**The fork is integrated by rebasing its commits onto `upstream/master`, never by merge.** `master`
carries fork commits on top of upstream, so it diverges as soon as upstream moves and neither `/pull`
nor a bare `git pull` applies (with rebase unset, git refuses a divergent pull); catch up through
`upstream-sync`.

**Propose a sync only when upstream cuts a release tag, never for ordinary master commits.** Upstream
moves most days, and every sync puts the checkout further ahead of the build serving as the
daily driver, which only a deliberate deploy replaces — so a sync per push buys churn rather than
currency. Compare the newest upstream tag against the checkout's own before raising it:

```bash
git fetch upstream --tags --quiet
git tag --list 'v[0-9]*' --sort=-v:refname | head -1   # against: git describe --tags --abbrev=0
```

**`gh` answers about upstream here, not about the fork.** With both remotes present it resolves the
base repository to `upstream`, so `gh run list`, `gh repo view` and the rest report `umputun/agterm`
unless `--repo AnotherSava/agterm` is passed. That returned an empty run list for a sha pushed to the
fork, which reads exactly like CI lagging behind the push.

**The same split makes `/commit` re-review what it has already reviewed.** The commit skill's
`change_scope.py` bounds the unpushed range with `@{upstream}..HEAD`, reaching
`HEAD --not --remotes` only when no upstream resolves, so nothing checks that the tracked remote is
the push remote — and here every commit already on the fork counts as unpushed. Expect `clean-code`
and `docs-relevance` to verdict `RUN` on every run, over files they reviewed in an earlier one.
`git rev-list HEAD --not --remotes` is the count that is actually true. Reported to the dotfiles
repo's own session on 2026-10-04; its user left the one-line fix for later, so this stands.

**Cut PR branches from `upstream/master`, never from this fork's master.** This fork's `.gitignore`
differs from upstream's two ways, and a branch based on this master carries both into the diff. It
carries re-include lines upstream does not have — for the conventions record, project memory, memos,
`settings.json`, the commit gate and `repo-flags`, all of which `.claude/*` would otherwise hide.
And it drops upstream's `.DS_Store` line, which is covered by this machine's global excludes but by
nothing a contributor on another machine has, so that removal is only ever correct inside this fork.

**The daily driver is a local Release build installed at `/Applications/agterm.app`.** The Homebrew
cask is uninstalled. Catching that app up means `make deploy INSTALL_DIR=/Applications`, which the
`deploy` skill runs here: the committed `config/deploy.env` names `DEPLOY_TYPE=make`, and the ignored
`config/deploy.local.env` holds `INSTALL_DIR=/Applications`, so another clone needs that file written
by hand or it installs to the Makefile's default, `~/Applications`. The project notes name that
directory as the deploy target, which was right while the cask held `/Applications`
and is wrong now, because a Release build carries upstream's own bundle identifier and two copies of
it would contend for one state directory, one socket lock and one preferences domain. `agtermctl`
reaches it from `/usr/local/bin`, installed through Help ▸ Install Command Line Tool rather than the
cask's Homebrew symlink.

That build is ad-hoc signed, so its privacy grants are keyed to a code signature that changes on
every rebuild, and it carries `com.apple.security.get-task-allow` where the notarized cask build did
not. Development therefore stays in Debug, which has its own bundle identifier and state directory
and leaves the daily driver alone — with one exception. `DebugStateDirectory.configStateDirectory`
returns nil for the `agterm-debug` sibling, so a Debug instance reads and writes the real
`~/.config/agterm`: Settings or Edit Keymap inside it change the live `keymap.conf` and
`ghostty.conf`, which no state isolation covers.

**Xcode 27 builds this repo**, though the project notes name Xcode 26. Verified at `7363c25` on
macOS 27.0.1 with Xcode 27.0 (27A266a): Debug and Release both built, 4,039 host-free tests and
1,156 hosted tests passed, and strict lint was clean. `scripts/setup.sh` already carries a zig
`float.h` shim written for the macOS 27 SDK, so upstream compiles against it too. This stays here
rather than in `CLAUDE.md` because that file is upstream's and an edit to it would ride into every
PR branch cut from this fork's master.

**This fork carries a libghostty patch that upstream does not.** Upstream's
`scripts/ghostty-patches/` holds its own numbered patches (`0001`–`0004` at v0.44.1); the fork adds
`anothersava-0001-clicks-only-mouse-leaves-pointer.patch`, and the README there says what each
changes. Fork patches carry their own `anothersava-NNNN` series, named after the fork owner and chosen
by the user on 2026-11-24, so upstream adding a patch never renames them; the glob sorts them after
upstream's. The digest in `.ghostty-build-stamp` covers
all of them, so a stamp from an upstream-only build never matches this checkout's. The user chose the
patch's wider scope on 2026-10-10 knowing its cost: no program that tracks only clicks (DECSET 1000 or
X10, such as htop, mc, or Claude Code's fullscreen UI) receives mouse presses in this build. Keep it out
of PR branches cut from `upstream/master`, and re-apply it by hand whenever `GHOSTTY_REV` moves or
upstream's patches change the same lines.

**`session split command` is fork-only and local-only.** The dotfiles remote-session `attach.sh` sets it
so ⌘D in a remote tab opens a second ssh connection. Upstream (v0.43+) runs a remote or attached row's
split on its host, which carries no split command, so the fork refuses it there
(`splitCommandRemoteRefusal`) rather than letting it silently not run.

**Fork code goes in its own files.** Upstream keeps several files at their lint ceilings (at v0.44.1
`Session.swift` was 999 of 1000 lines and `agtermctl`'s `Session` struct near its 800-line body limit),
so any fork addition inside them fails strict lint. The split command's state sits behind one stored
`Session.forkSplit` with its type in `Session+SplitCommand.swift`, and its CLI in
`SessionCommands+SplitCommand.swift`; a sync then conflicts on one line instead of a block.

**How to undo it.** The notarized cask bundle that was replaced is kept, signature intact, at
`~/agterm-0.25.0-cask.app`, and the pre-switch state directory at
`~/agterm-backup-20261004-104201`. Restoring the bundle means removing `/Applications/agterm.app`
first — Homebrew and `cp` both refuse to move onto a target they do not own.
