# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A literate Doom Emacs configuration implementing a personal **"Life OS"** — a
PPV (Pillars, Pipelines, Vaults) productivity system built on org-mode,
org-roam, org-agenda, calfw, and org-super-agenda. The full design spec lives
in `life-os-prd.md`; read it for the *why* behind the org folder structure,
review cadences, and PPV mental model.

This directory is the Doom config directory (`$DOOMDIR`).
`~/.config/doom` is a symlink to it, and the repo root is `~/dotfiles`
(this is `dotfiles/doom/`).

## Cross-platform

This same config runs on **two machines**: an Omarchy (Arch Linux) box and a
Windows 11 box. The config should stay portable across both. There is currently
a **known discrepancy between the two machines** (behavior/state differs somehow)
— to be diagnosed and fixed later. When making changes, prefer platform-agnostic
defaults; gate anything OS-specific (paths, fonts, executables) on
`(featurep :system 'windows)` / `'linux` rather than hardcoding.

## Literate config — the one rule that matters

`config.el` is **generated**, never hand-edited. Doom's `:config literate`
module auto-tangles `config.org` → `config.el` on every `doom sync`. All
configuration changes go in **`config.org`**. Editing `config.el` directly will
be silently overwritten on the next tangle.

- `config.el.backup` is the original Doom template, kept for reference only.
- `custom.el` is written by Emacs' Customize UI — leave it to the machine.

## Common commands

```bash
doom sync          # re-tangle config.org → config.el, install/remove packages,
                   # rebuild. Run after editing init.el, packages.el, or config.org.
doom doctor        # diagnose a broken config
doom upgrade       # update Doom + packages
```

`doom` lives at `~/.config/emacs/bin/doom` (also on PATH).

Inside a running Emacs, the fast live-edit loop (no shell needed):
1. `M-x org-babel-tangle` from inside `config.org` — regenerates `config.el`.
2. `M-x doom/reload` — applies it.

There is no test suite, linter, or build step beyond `doom sync` / `doom doctor`.

## Where to change what

- **`init.el`** — which Doom *modules* are enabled (the `doom!` block). Toggling
  a module here requires `doom sync`. Key enabled modules: `vertico`+`corfu`
  completion, `evil +everywhere` (vim everywhere), `org +roam +dragndrop +pretty`,
  `magit`, `vterm`, `:config literate`.
- **`packages.el`** — third-party package declarations (`package!`). The Life OS
  additions are at the bottom: `org-super-agenda`, `calfw`/`calfw-org`,
  `org-modern`, `org-roam-ui`, `olivetti`, `catppuccin-theme`. Requires `doom sync`.
- **`config.org`** — all actual configuration, organized into top-level headings
  (each with a `:CUSTOM_ID:`): Startup, Org base, Org-roam, Roam capture
  templates, Standard capture templates, Super-agenda groups, Custom agenda
  commands, Calfw, Review capture templates, Keybindings, Org writing experience,
  LaTeX previews, Visual config.
- **`templates/`** — `org-capture` body templates for the four review cadences
  (weekly/monthly/quarterly/annual). The daily review is generated inline.

## Architecture notes

- **The data lives in `~/org/`, not in this repo.** Config here points at
  `~/org/` subfolders: `goals/`, `pillars/`, `projects/`, `daily/`, `knowledge/`
  (`concepts/`, `literature/`, `fleeting/`), `meetings/`, plus `inbox.org`.
  `org-agenda-files` and the roam capture templates encode this layout — keep
  them in sync if the folder structure changes.
- **org-roam is the relational backbone.** Hierarchy (Goal → Pillar → Project →
  notes) is enforced two ways: `:filetags:` on each node, and an explicit
  `[[id:...]]` parent link inserted at capture time. The helper
  `life-os/roam-link-by-tag` (in the Roam capture section) prompts for a parent
  node filtered by tag and degrades gracefully to an empty string when no parent
  exists yet (e.g. the very first Pillar).
- **Conventions to match when editing `config.org`:** wrap settings in
  `(after! org ...)` / `(use-package! ...)` as the existing blocks do; the user
  is new to Emacs, so every non-trivial block carries an explanatory comment —
  preserve that density. Colors throughout use the **Catppuccin Macchiato**
  palette (hex codes are commented inline).
- **Keybindings** are leader-prefixed under `SPC A` (agenda dashboards) and
  `SPC X` (express capture / reviews); roam capture is Doom's default `SPC n c`.
  Note `SPC X` is intentionally redefined as a prefix-map, shadowing Doom's
  default `SPC X` → `org-capture` (still reachable via `C-c c`). The Keybindings
  section also contains a deliberate workaround forcing `j`/`k` to stay motion
  keys on org-super-agenda header lines.

## TODO workflow

Keyword sequence: `TODO → STRT (in progress) → WAIT (blocked)` then
`DONE | KILL (dropped)`. `KILL` is distinct from `DONE` on purpose — it keeps
honest review data. Completed tasks archive to a `* Archive` heading at the
bottom of the same file.

## Gotchas

- **Doom sets global agenda defaults that silently override custom commands.**
  `modules/lang/org/config.el` sets `org-agenda-span 10`,
  `org-agenda-start-on-weekday nil`, and **`org-agenda-start-day "-3d"`**. Any
  `agenda` block in `org-agenda-custom-commands` that does *not* set
  `org-agenda-start-day` itself inherits the `-3d` offset and starts three days
  in the past — this is what made the Daily dashboard (`SPC A D`) show the 29th
  instead of today. **Always set `org-agenda-start-day` explicitly in every
  agenda block** (`nil` = today). This reproduces identically on both machines
  because it's a Doom default, not local state. General lesson: when a custom
  setting "doesn't take," check whether Doom's module already set that variable
  globally — `grep` the relevant `~/.config/emacs/modules/.../config.el`.
- **Custom-command setting values *are* evaluated.** In
  `org-agenda-custom-commands`, each `(var value)` has its `value` passed through
  `eval` (see `org-agenda.el` `org-agenda-run-series`). So `'(closed clock state)`
  must keep its quote, and `nil` correctly evaluates to today.
- **`config.el` is tangled without a `lexical-binding` cookie** (first line is
  plain code), so the whole config runs under *dynamic* binding. Lambdas can't
  close over `let`-bound vars — pass them as explicit arguments instead (e.g. the
  calfw resize timer passes the buffer as a timer arg, not a closure). Adding the
  cookie is a worthwhile but separate change (test-and-reload on its own).
- **`calfw-calendar-mode` is hand-rolled, not `define-derived-mode`.** It never
  runs `after-change-major-mode-hook`, so evil doesn't auto-pick a state and its
  bindings shadow calfw's keys (frozen calendar). Fixed by forcing evil emacs
  state. Hand-rolled major modes are the likely culprit for other Linux/Win11
  evil divergences.
- **`doom sync` is broken on Windows due to an upstream Doom bug.** The literate
  module's post-tangle restart script (`modules/config/literate/autoload.el:65`)
  hardcodes bash syntax (`__NOTANGLE=1 $@`), which PowerShell rejects. Workaround:
  `$env:__NOTANGLE = 1` is set in the PowerShell profile
  (`~/.config/powershell/user_profile.ps1`) to skip the tangle/restart step
  entirely. This is the correct behavior on Windows anyway — `config.org` is only
  edited on Arch, and Windows just consumes the committed `config.el`. Just run
  `doom sync` normally.
