# ghostty patches

`scripts/setup.sh` applies every `*.patch` here, in name order, to the fresh checkout of `GHOSTTY_REV`
before building libghostty. Their digest is part of `.ghostty-build-stamp`, so editing one rebuilds
libghostty exactly as a `GHOSTTY_REV` change does.

Each patch is a plain `diff -ruN` against a pristine copy of the tree, made so `git apply` takes it with
`-p1`. To change one, check out `GHOSTTY_REV` twice as `ghostty-orig` and `ghostty`, apply the patches to
`ghostty`, edit, and regenerate the file with `diff -ruN ghostty-orig/<file> ghostty/<file>`. Moving
`GHOSTTY_REV` means re-applying them by hand where they no longer apply.

- `0001-clicks-only-mouse-leaves-pointer.patch` gives the pointer back to the terminal while a program
  asks only for button presses (X10 or DECSET 1000), as Claude Code's fullscreen UI does. Such a program
  still receives the wheel, but ⌘-hover and ⌘-click reach links, plain drag selects, and presses are
  no longer reported to it, without holding Shift. A program tracking motion (1002 or 1003) keeps the
  mouse as upstream gives it. Upstream treats ⌘⇧ under any capture as deliberate (ghostty #1416).
