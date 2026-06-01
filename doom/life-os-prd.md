# Life OS for Doom Emacs — Implementation PRD

**Version:** 1.0
**Target environment:** Fresh install of Doom Emacs (latest stable), Emacs 29+
**Implementation agent:** Claude Code

---

## 1. Overview

This document specifies the configuration of a personal Life OS built on top of Doom Emacs. The system combines:

- **PPV (Pillars, Pipelines, Vaults)** organizing structure, inspired by August Bradley's Notion system.
- **Org-roam** as the relational backbone (replaces Notion's linked databases).
- **Org-agenda + calfw + org-super-agenda** as the calendar / dashboard UI.
- **Zettelkasten-style knowledge notes** integrated into the same graph.
- **A multi-cadence review system** (daily / weekly / monthly / quarterly / annual).

Everything is plain text, local, keyboard-driven, and works with evil-mode (vim motions).

---

## 2. How to Use This PRD (Instructions for Claude Code)

- Implement **phase by phase** as defined in Section 8. Do not jump ahead.
- **Configuration is literate.** The user's `config.el` is auto-tangled from `~/.config/doom/config.org` by Doom's `literate` module. All config edits happen in `config.org`, never in `config.el` directly (it gets overwritten on tangle).
- After modifying `init.el`, `packages.el`, or `config.org`, run `doom sync` from the terminal. `doom sync` triggers the tangle. For live-editing during a session, `M-x org-babel-tangle` (from inside `config.org`) re-tangles immediately, then `M-x doom/reload`.
- Before declaring a phase complete, run the **verification steps** for that phase.
- The user is **new to Emacs** — favor robust, well-documented defaults over clever tricks. Add comments to every non-trivial config block.
- If a package name or API has changed between this PRD and the current ecosystem, prefer the current canonical name and note the change.
- Do **not** modify files outside `~/.config/doom/` and `~/org/`.

---

## 3. Background & Philosophy

The user previously used Notion with August Bradley's "Life OS" Pillars/Pipelines/Vaults framework. The core mental model:

- **Value Goals**: non-tangible, deeply personal aspirations (e.g. "be able to wear a shirt off the rack").
- **Pillars**: life domains that serve those goals (e.g. fitness, food, learning).
- **Projects**: tangible, time-bounded efforts under a pillar.
- **Tasks**: atomic actions inside a project.
- **Pipelines**: recurring workflows with fixed process flows.
- **Vaults**: notes and knowledge.

The user moved off Notion for data privacy and ownership reasons, then through Obsidian, and is now committed to Emacs/org-mode for plain text, keyboard control, and evil-mode (vim motions).

The system must preserve the **hierarchy and relations of PPV** while delivering a **calendar-first daily UX** so the day-to-day work doesn't require thinking about the bigger picture.

---

## 4. Goals

- **Calendar view of tasks** as the daily driver — month grid + day/week tabular view, both keyboard-navigable.
- **Relational PPV structure** — goals → pillars → projects → tasks, navigable via backlinks.
- **Three kinds of notes**: project-attached, knowledge (zettelkasten), daily log.
- **Multi-cadence reviews** with prefilled templates and review-specific dashboards.
- **Frictionless capture** — adding a task, note, or daily entry should take under 5 keystrokes from anywhere.
- **Privacy and ownership** — everything is plain `.org` files on local disk.
- **Keyboard-only** — no required mouse interaction.

## Non-Goals (Phase 1)

- Web UI, browser dashboard, or mobile sync.
- AI-assisted features inside the system.
- External task tool integration.
- Bookkeeping or finance tracking (user handles separately).
- Pipelines (will be added in a future phase; the architecture supports them but they are not configured here).

---

## 5. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ONE ORG-ROAM GRAPH                       │
│                                                             │
│  ┌──────────────┐                                           │
│  │ Value Goals  │ ← roam nodes (goals/*.org)                │
│  └──────┬───────┘                                           │
│         │ [[id:]]                                           │
│  ┌──────▼───────┐                                           │
│  │   Pillars    │ ← roam nodes (pillars/*.org)              │
│  └──────┬───────┘                                           │
│         │ [[id:]]                                           │
│  ┌──────▼───────┐                                           │
│  │   Projects   │ ← roam nodes (projects/*.org)             │
│  │              │   each contains TODO headings = tasks     │
│  └──────────────┘                                           │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Knowledge   │  │   Meetings   │  │    Daily     │       │
│  │  zettel      │  │  notes       │  │   journal    │       │
│  │  nodes       │  │  nodes       │  │   nodes      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │   Reviews    │  │   Inbox /    │                         │
│  │  documents   │  │   Someday    │                         │
│  └──────────────┘  └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
              │
              ▼
   ┌──────────────────────┐
   │   Daily UX layer     │
   │  • org-agenda day/   │
   │    week views        │
   │  • calfw month grid  │
   │  • org-super-agenda  │
   │    groups            │
   └──────────────────────┘
```

**Key principle: tasks are NOT roam nodes.** Tasks are TODO headings living inside a project's roam file (or pillar file for pillar-direct tasks, or inbox for one-offs). This avoids node proliferation while preserving "which project does this belong to" via file location.

---

## 6. Folder Structure

All under `~/org/`:

```
~/org/
├── goals/              # Value goal roam nodes
├── pillars/            # Pillar roam nodes
├── projects/           # Project roam nodes (TODO headings live inside)
├── knowledge/          # Zettelkasten
│   ├── concepts/       # Permanent / evergreen notes
│   ├── literature/     # Notes on books, papers, articles
│   └── fleeting/       # Raw captures awaiting processing
├── meetings/           # Substantial meeting / discussion notes
├── daily/              # org-roam-dailies (YYYY-MM-DD.org per day)
├── reviews/
│   ├── weekly/         # 2026-W22.org, ...
│   ├── monthly/        # 2026-05.org, ...
│   ├── quarterly/      # 2026-Q2.org, ...
│   └── annual/         # 2026.org, ...
├── archive/            # Long-term archived files (e.g. completed projects)
├── inbox.org           # Quick-capture for one-off tasks (NOT a roam node)
└── someday.org         # Parked project ideas (NOT a roam node)
```

Inside each project/pillar file, completed tasks are archived to a `* Archive` heading at the bottom of the same file (configured via `org-archive-location`).

---

## 7. Prerequisites

- [ ] Fresh Doom Emacs installation (latest stable from https://github.com/doomemacs/doomemacs).
- [ ] Emacs 29 or later.
- [ ] Git installed.
- [ ] `~/.config/doom/` exists with default Doom scaffolding (`init.el`, `packages.el`, `config.el`). The default `config.el` will be replaced by a literate `config.org` (which tangles to a fresh `config.el`).

If any of these are missing, install/scaffold them before proceeding.

---

## 8. Implementation Plan

Each phase has: tasks → config changes → verification. Complete in order.

> **Note on workflow.** All references below to "add X block to `config.org`" mean: append the elisp under the corresponding org heading in `~/.config/doom/config.org`, wrapped in a `#+begin_src emacs-lisp :tangle yes ... #+end_src` block (see Section 9.3 for the literate template). "Reload config" means tangle (`doom sync` or `M-x org-babel-tangle`) then `M-x doom/reload`.

### Phase 1 — Foundation

- [ ] Create the full folder structure under `~/org/` (see Section 6).
- [ ] In `~/.config/doom/init.el`, ensure these modules are enabled (uncommented):
  - `:editor (evil +everywhere)` (default)
  - `:lang (org +roam2)`
  - `:tools magit` (helpful for backup/sync)
  - `:config (literate)` — enables literate config via `config.org`
- [ ] In `~/.config/doom/packages.el`, add:
  - `(package! org-super-agenda)`
  - `(package! calfw)`
  - `(package! calfw-org)`
  - `(package! org-modern)`
  - `(package! org-roam-ui)` *(optional; graph visualization)*
- [ ] Create `~/.config/doom/config.org` with the literate skeleton from Section 9.3 (title, headings for each subsection 9.3.1–9.3.10, empty `#+begin_src emacs-lisp :tangle yes ... #+end_src` blocks ready to be filled in subsequent phases).
- [ ] Remove or move aside the default `~/.config/doom/config.el` — it will be regenerated by the tangle on `doom sync`.
- [ ] Run `doom sync`.

**Verification:** Emacs starts cleanly. `doom sync` tangles `config.org` into `config.el` without errors. `M-x org-roam-node-find` exists. `M-x cfw:open-org-calendar` exists. `M-x org-super-agenda-mode` exists.

### Phase 2 — Org Base Config

- [ ] Add the **Org base** block (Section 9.3.1) to `config.org`.
- [ ] Re-tangle and reload config.

**Verification:** Open any `.org` file. `C-c C-t` cycles through TODO → STRT → WAIT → DONE → KILL. Marking a task DONE inserts a CLOSED timestamp inside a `:LOGBOOK:` drawer. `C-c C-x C-a` archives a subtree to a `* Archive` heading in the same file.

### Phase 3 — Org-roam + PPV Capture

- [ ] Add the **Org-roam** block (Section 9.3.2) to `config.org`.
- [ ] Add the **Roam capture templates** block (Section 9.3.3) to `config.org`.
- [ ] Re-tangle and reload config.
- [ ] Create one example value goal, one pillar (linked to the goal), and one project (linked to the pillar). See Section 10.3 for examples.

**Verification:** `SPC n r f` opens a node finder. Creating a new project via the capture template prompts for a pillar and prefills the link. From the pillar's roam buffer, the new project shows as a backlink.

### Phase 4 — Daily Flow

- [ ] Add the **Capture templates** block (Section 9.3.4) — inbox, quick task, dailies — to `config.org`.
- [ ] Add the **Super-agenda groups** block (Section 9.3.5) to `config.org`.
- [ ] Add the **Daily agenda dashboard** custom command (part of Section 9.3.6) to `config.org`.
- [ ] Create empty `~/org/inbox.org` and `~/org/someday.org` (see Section 10.1, 10.2).
- [ ] Re-tangle and reload config.

**Verification:** `SPC X` opens inbox capture. `SPC n r d t` opens today's daily journal with a time-stamped entry template. `SPC o A D` (or whatever the daily review binding is) opens the daily dashboard agenda view, grouped by pillar/project.

### Phase 5 — Calendar View

- [ ] Add the **Calfw config** block (Section 9.3.7) to `config.org`.
- [ ] Re-tangle and reload config.

**Verification:** `SPC o c` opens a month grid calendar showing scheduled org tasks. Keyboard navigation works (`n`/`p` to navigate days, `M-n`/`M-p` for months, `Enter` to jump to the task).

### Phase 6 — Review System

- [ ] Add the **Review capture templates** block (Section 9.3.8) to `config.org`.
- [ ] Add the **Review custom agenda commands** block (Section 9.3.9) to `config.org`.
- [ ] Re-tangle and reload config.
- [ ] Verify the `reviews/` subdirectories exist.

**Verification:**
- `SPC X w` creates a new weekly review file with all prompts prefilled.
- `SPC X m`, `SPC X q`, `SPC X y` work for monthly, quarterly, annual.
- `SPC o A w` opens the weekly review dashboard agenda.
- The weekly review file's clocktable populates correctly when you run `C-c C-c` on the `#+BEGIN: clocktable` line.

### Phase 7 — Keybindings & Cheatsheet

- [ ] Add the **Keybindings** block (Section 9.3.10) to `config.org`.
- [ ] Generate `~/org/CHEATSHEET.org` with the contents in Section 12.
- [ ] Re-tangle and reload config.

**Verification:** All custom bindings work and are discoverable via `SPC` (`which-key` shows them).

### Phase 8 — Visual Polish

- [ ] Verify the **JetBrains Mono** font is installed on the system. If not, install it first (Linux: package manager or download from https://www.jetbrains.com/lp/mono/; macOS: `brew install --cask font-jetbrains-mono`; WSL: install in the host Windows). Do not proceed until the font is available.
- [ ] Add the **Visual config** block (Section 9.3.11) to `config.org`.
- [ ] Re-tangle and reload config.
- [ ] Run `M-x nerd-icons-install-fonts` if not already done (gives modeline and dired their icon glyphs).

**Verification:** Emacs renders in JetBrains Mono. The `doom-tokyo-night` theme is active (verify via `M-x describe-variable doom-theme`). Opening any `.org` file shows org-modern styling: cleaner bullets, modern table borders, styled `#+begin_src` blocks, dates rendered as pill-shaped labels.

---

## 9. Configuration Files (Complete)

### 9.1 `~/.config/doom/init.el`

Ensure the following lines are present and uncommented (other lines should remain as Doom's defaults):

```elisp
:config
(literate)      ; tangle config.org → config.el on doom sync

:editor
(evil +everywhere)

:lang
(org
 +roam2          ; enable org-roam v2
 +dragndrop      ; drag/drop images into org files
 +pretty)        ; nicer org bullets and visuals
```

### 9.2 `~/.config/doom/packages.el`

```elisp
;; Life OS additions
(package! org-super-agenda)
(package! calfw)
(package! calfw-org)
(package! org-modern)    ; modern visual styling for org-mode
(package! org-roam-ui)   ; optional: graph visualization at http://localhost:35901
```

### 9.3 `~/.config/doom/config.org`

This is the literate config. Each subsection below (9.3.1–9.3.10) is written as an org heading in `config.org`, with prose explanation followed by an `emacs-lisp` source block that is tangled into `config.el` on `doom sync`. The user edits this file, never the generated `config.el`.

**Skeleton structure of `config.org`:**

````org
#+title: Doom Emacs — Life OS Configuration
#+property: header-args:emacs-lisp :tangle yes :results silent
#+startup: overview

* Org base
:PROPERTIES:
:CUSTOM_ID: org-base
:END:

Brief prose describing what this block does and why.

#+begin_src emacs-lisp
;; ... elisp from Section 9.3.1 goes here ...
#+end_src

* Org-roam
:PROPERTIES:
:CUSTOM_ID: org-roam
:END:

#+begin_src emacs-lisp
;; ... elisp from Section 9.3.2 ...
#+end_src

* Roam capture templates (PPV + Vault)
...

* Standard capture templates (inbox, quick tasks, dailies)
...

* Super-agenda groups
...

* Custom agenda commands (review dashboards)
...

* Calfw (calendar grid view)
...

* Review capture templates
...

* Keybindings
...

* Visual config
...
````

Notes on the literate setup:
- The `#+property: header-args:emacs-lisp :tangle yes` line on top sets tangling as the default for every `emacs-lisp` block in the file. You don't have to repeat `:tangle yes` on each block.
- Individual blocks can opt out with `:tangle no` if you want to keep elisp examples in prose without executing them.
- Doom's `:config (literate)` module auto-tangles `config.org` → `config.el` whenever you run `doom sync`. Manual tangling is `M-x org-babel-tangle` from inside the file.
- Use `org-edit-special` (`C-c '`) to edit a source block in a proper emacs-lisp buffer with full lisp-mode support — paren matching, eldoc, etc. This is the killer feature of literate editing.

The subsections below show the elisp content for each block. In `config.org`, each is wrapped in `#+begin_src emacs-lisp ... #+end_src` under its heading.

#### 9.3.1 Org base

```elisp
;; ──────────────────────────────────────────────────────────
;; Org directory and agenda files
;; ──────────────────────────────────────────────────────────
(setq org-directory "~/org/")

(after! org
  ;; Files that contribute TODOs to the agenda.
  (setq org-agenda-files
        (list (concat org-directory "goals/")
              (concat org-directory "pillars/")
              (concat org-directory "projects/")
              (concat org-directory "daily/")
              (concat org-directory "inbox.org")))

  ;; ────────────────────────────────────────────────────────
  ;; TODO keywords
  ;;   TODO  - not started
  ;;   STRT  - in progress (currently working on)
  ;;   WAIT  - blocked on someone/something
  ;;   DONE  - finished
  ;;   KILL  - dropped (different from done; useful for honest review)
  ;;
  ;; (s/w/d/k/etc.) = single-key shortcut after C-c C-t
  ;; !   = log a timestamp on state entry
  ;; @   = prompt for a note on state entry
  ;; /!  = log timestamp on state EXIT
  ;; ────────────────────────────────────────────────────────
  (setq org-todo-keywords
        '((sequence "TODO(t)" "STRT(s)" "WAIT(w@/!)"
                    "|"
                    "DONE(d!)" "KILL(k@)")))

  ;; Color the state keywords for quick visual scanning.
  (setq org-todo-keyword-faces
        '(("TODO" . (:foreground "#cc241d" :weight bold))
          ("STRT" . (:foreground "#d79921" :weight bold))
          ("WAIT" . (:foreground "#928374" :weight bold))
          ("DONE" . (:foreground "#98971a" :weight bold))
          ("KILL" . (:foreground "#504945" :weight bold))))

  ;; Always record a timestamp when marking DONE.
  (setq org-log-done 'time)
  ;; Tuck state-change log entries into a :LOGBOOK: drawer (folded by default).
  (setq org-log-into-drawer t)

  ;; ────────────────────────────────────────────────────────
  ;; Archive
  ;; ────────────────────────────────────────────────────────
  ;; Archive completed tasks to a "* Archive" heading at the bottom
  ;; of the SAME file. Keeps history with the project for grep/review.
  (setq org-archive-location "::* Archive")

  ;; ────────────────────────────────────────────────────────
  ;; Misc quality-of-life
  ;; ────────────────────────────────────────────────────────
  (setq org-startup-folded 'content        ; show headings on open
        org-startup-indented t              ; indent by heading level
        org-hide-emphasis-markers t         ; cleaner inline formatting
        org-pretty-entities t
        org-image-actual-width '(400)
        org-tags-column 0                   ; tags right after heading text
        org-fold-catch-invisible-edits 'smart))
```

#### 9.3.2 Org-roam

```elisp
;; ──────────────────────────────────────────────────────────
;; Org-roam (v2)
;; ──────────────────────────────────────────────────────────
(use-package! org-roam
  :custom
  (org-roam-directory (file-truename "~/org/"))
  (org-roam-dailies-directory "daily/")
  (org-roam-completion-everywhere t)
  ;; Display backlinks etc. in a side window.
  (org-roam-mode-section-functions
   (list #'org-roam-backlinks-section
         #'org-roam-reflinks-section))
  :config
  (org-roam-db-autosync-mode))
```

#### 9.3.3 Roam capture templates (PPV + Vault)

```elisp
;; ──────────────────────────────────────────────────────────
;; Roam capture templates
;;
;; Hierarchy enforced via :filetags and an explicit "Pillar"/"Goal" link
;; in the new file. The user picks the parent at capture time.
;; ──────────────────────────────────────────────────────────
(after! org-roam
  (setq org-roam-capture-templates
        '(("g" "Value Goal" plain
           "%?"
           :target (file+head "goals/${slug}.org"
                              "#+title: ${title}\n#+filetags: :goal:\n\n* Why this matters\n\n* Pillars supporting this goal\n")
           :unnarrowed t)

          ("p" "Pillar" plain
           "%?"
           :target (file+head "pillars/${slug}.org"
                              "#+title: ${title}\n#+filetags: :pillar:\n\n* Value goal\n%^{Linked goal}\n\n* Guiding principles\n\n* Projects\n\n* Pillar-level tasks\n")
           :unnarrowed t)

          ("r" "Project" plain
           "%?"
           :target (file+head "projects/${slug}.org"
                              "#+title: ${title}\n#+filetags: :project:\n\n* Pillar\n%^{Linked pillar}\n\n* Definition of done\n\n* Tasks\n\n* Notes\n")
           :unnarrowed t)

          ("c" "Concept (permanent note)" plain
           "%?"
           :target (file+head "knowledge/concepts/${slug}.org"
                              "#+title: ${title}\n#+filetags: :concept:\n")
           :unnarrowed t)

          ("l" "Literature note" plain
           "%?"
           :target (file+head "knowledge/literature/${slug}.org"
                              "#+title: ${title}\n#+filetags: :literature:\n\n* Source\n\n* Key ideas\n\n* My takeaways\n")
           :unnarrowed t)

          ("f" "Fleeting note" plain
           "%?"
           :target (file+head "knowledge/fleeting/${slug}.org"
                              "#+title: ${title}\n#+filetags: :fleeting:\n")
           :unnarrowed t)

          ("m" "Meeting note" plain
           "%?"
           :target (file+head "meetings/%<%Y-%m-%d>-${slug}.org"
                              "#+title: ${title}\n#+filetags: :meeting:\n#+date: %<%Y-%m-%d>\n\n* Attendees\n\n* Agenda\n\n* Decisions\n\n* Action items\n")
           :unnarrowed t))))
```

#### 9.3.4 Standard capture templates (inbox, quick tasks, dailies)

```elisp
;; ──────────────────────────────────────────────────────────
;; org-capture templates (non-roam)
;; ──────────────────────────────────────────────────────────
(after! org
  (setq org-capture-templates
        '(;; ── Inbox: one-off tasks, route during weekly review
          ("i" "Inbox task" entry
           (file "~/org/inbox.org")
           "* TODO %?\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:\n  %i"
           :empty-lines 1)

          ;; ── Someday/maybe
          ("s" "Someday / Maybe" entry
           (file "~/org/someday.org")
           "* %?\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:"
           :empty-lines 1)

          ;; ── Quick note into a project (prompts for project file)
          ("n" "Note under existing file" entry
           (file+headline (lambda ()
                            (read-file-name "Project file: "
                                            (concat org-directory "projects/"))))
           "* %?\n  %U"
           :empty-lines 1)

          ;; ── Reviews live here too; see 9.3.8 for the full set
          )))

;; ──────────────────────────────────────────────────────────
;; Org-roam dailies capture
;; ──────────────────────────────────────────────────────────
(after! org-roam
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d %A>\n#+filetags: :daily:\n"))

          ("j" "journal — interruption / conversation" entry
           "* %<%H:%M> %^{Topic} :journal:\n%?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d %A>\n#+filetags: :daily:\n")))))
```

#### 9.3.5 Super-agenda groups

```elisp
;; ──────────────────────────────────────────────────────────
;; Org-super-agenda — daily dashboard grouping
;; ──────────────────────────────────────────────────────────
(use-package! org-super-agenda
  :after org-agenda
  :init
  (setq org-super-agenda-groups
        '((:name "🔥 Overdue"
           :and (:scheduled past :not (:todo ("DONE" "KILL"))))
          (:name "📅 Today"
           :time-grid t
           :scheduled today)
          (:name "▶ In progress"
           :todo "STRT")
          (:name "⏸ Waiting on"
           :todo "WAIT")
          (:name "📥 Inbox"
           :file-path "inbox\\.org")
          (:name "🗓 Upcoming this week"
           :scheduled future
           :order 90)
          ;; Everything else: group by category (= filename = project)
          (:auto-category t
           :order 100)))
  :config
  (org-super-agenda-mode))
```

#### 9.3.6 Custom agenda commands (daily / weekly / monthly / quarterly review dashboards)

```elisp
;; ──────────────────────────────────────────────────────────
;; Custom agenda commands
;;
;; D = Daily dashboard           (~5 min review)
;; W = Weekly dashboard          (~45–60 min)
;; M = Monthly dashboard         (~60–90 min)
;; Q = Quarterly dashboard       (~2–3 hr)
;; Y = Annual dashboard          (~half day)
;; ──────────────────────────────────────────────────────────
(after! org-agenda
  (setq org-agenda-custom-commands
        '(("D" "Daily dashboard"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-start-with-log-mode '(closed clock state))
                     (org-agenda-overriding-header "📅 TODAY")))
            (todo "STRT"
                  ((org-agenda-overriding-header "▶ In progress")))
            (todo "WAIT"
                  ((org-agenda-overriding-header "⏸ Waiting on")))
            (tags "inbox"
                  ((org-agenda-files (list (concat org-directory "inbox.org")))
                   (org-agenda-overriding-header "📥 Inbox")))))

          ("W" "Weekly dashboard"
           ((agenda ""
                    ((org-agenda-span 7)
                     (org-agenda-start-day "-7d")
                     (org-agenda-start-with-log-mode '(closed))
                     (org-agenda-overriding-header "📊 PAST WEEK")))
            (agenda ""
                    ((org-agenda-span 7)
                     (org-agenda-start-day "+1d")
                     (org-agenda-overriding-header "🔮 NEXT WEEK")))
            (todo "STRT|WAIT"
                  ((org-agenda-overriding-header "▶/⏸ Active and Blocked")))))

          ("M" "Monthly dashboard"
           ((agenda ""
                    ((org-agenda-span 'month)
                     (org-agenda-start-day "-1m")
                     (org-agenda-start-with-log-mode '(closed))
                     (org-agenda-overriding-header "📊 PAST MONTH")))
            (todo "TODO|STRT|WAIT"
                  ((org-agenda-overriding-header "🗂 All open work")))))

          ("Q" "Quarterly dashboard"
           ((agenda ""
                    ((org-agenda-span 90)
                     (org-agenda-start-day "-90d")
                     (org-agenda-start-with-log-mode '(closed))
                     (org-agenda-overriding-header "📊 PAST QUARTER")))
            (tags "+fleeting"
                  ((org-agenda-overriding-header "💭 Fleeting notes to process")))))

          ("Y" "Annual dashboard"
           ((agenda ""
                    ((org-agenda-span 365)
                     (org-agenda-start-day "-365d")
                     (org-agenda-start-with-log-mode '(closed))
                     (org-agenda-overriding-header "📊 PAST YEAR")))))

          ;; Quick access to the default unified agenda
          ("a" "All TODOs grouped"
           ((todo "TODO|STRT|WAIT"))))))
```

#### 9.3.7 Calfw (calendar grid view)

```elisp
;; ──────────────────────────────────────────────────────────
;; Calfw — month grid calendar populated from org-agenda
;; ──────────────────────────────────────────────────────────
(use-package! calfw
  :commands (cfw:open-org-calendar))

(use-package! calfw-org
  :after calfw
  :config
  (setq cfw:org-overwrite-default-keybinding t))

;; Optional: a nicer face palette
(after! calfw
  (setq cfw:fchar-junction         ?╋
        cfw:fchar-vertical-line    ?┃
        cfw:fchar-horizontal-line  ?━
        cfw:fchar-left-junction    ?┣
        cfw:fchar-right-junction   ?┫
        cfw:fchar-top-junction     ?┯
        cfw:fchar-top-left-corner  ?┏
        cfw:fchar-top-right-corner ?┓))
```

#### 9.3.8 Review capture templates

These extend `org-capture-templates`. Merge with the block in 9.3.4.

```elisp
;; ──────────────────────────────────────────────────────────
;; Review capture templates
;;
;; Each creates a new dated file with prefilled prompts.
;; Clocktables auto-populate when you press C-c C-c inside the block.
;; ──────────────────────────────────────────────────────────
(after! org
  (add-to-list 'org-capture-templates
               '("w" "Weekly review" plain
                 (file (lambda ()
                         (let ((file (format-time-string
                                      "~/org/reviews/weekly/%Y-W%V.org")))
                           (unless (file-exists-p file)
                             (with-temp-file file ""))
                           file)))
                 (file "~/.config/doom/templates/weekly-review.org")
                 :unnarrowed t :immediate-finish nil))

  (add-to-list 'org-capture-templates
               '("m" "Monthly review" plain
                 (file (lambda ()
                         (let ((file (format-time-string
                                      "~/org/reviews/monthly/%Y-%m.org")))
                           (unless (file-exists-p file)
                             (with-temp-file file ""))
                           file)))
                 (file "~/.config/doom/templates/monthly-review.org")
                 :unnarrowed t))

  (add-to-list 'org-capture-templates
               '("q" "Quarterly review" plain
                 (file (lambda ()
                         (let* ((month (string-to-number (format-time-string "%m")))
                                (q (1+ (/ (1- month) 3)))
                                (year (format-time-string "%Y"))
                                (file (format "~/org/reviews/quarterly/%s-Q%d.org" year q)))
                           (unless (file-exists-p file)
                             (with-temp-file file ""))
                           file)))
                 (file "~/.config/doom/templates/quarterly-review.org")
                 :unnarrowed t))

  (add-to-list 'org-capture-templates
               '("y" "Annual review" plain
                 (file (lambda ()
                         (let ((file (format-time-string
                                      "~/org/reviews/annual/%Y.org")))
                           (unless (file-exists-p file)
                             (with-temp-file file ""))
                           file)))
                 (file "~/.config/doom/templates/annual-review.org")
                 :unnarrowed t)))
```

The template files (`weekly-review.org`, etc.) should be created in `~/.config/doom/templates/`. See Section 10.4 for their contents.

#### 9.3.9 *(reserved — review agenda commands are already in 9.3.6)*

#### 9.3.10 Keybindings

```elisp
;; ──────────────────────────────────────────────────────────
;; Keybindings
;; ──────────────────────────────────────────────────────────
(map! :leader
      ;; Calendar
      (:prefix-map ("o" . "open")
       :desc "Calfw month calendar"        "c" #'cfw:open-org-calendar)

      ;; Custom agenda dashboards
      (:prefix-map ("A" . "agenda dashboards")
       :desc "Daily"      "D" (cmd! (org-agenda nil "D"))
       :desc "Weekly"     "W" (cmd! (org-agenda nil "W"))
       :desc "Monthly"    "M" (cmd! (org-agenda nil "M"))
       :desc "Quarterly"  "Q" (cmd! (org-agenda nil "Q"))
       :desc "Annual"     "Y" (cmd! (org-agenda nil "Y")))

      ;; Captures (X for eXpress capture, to avoid collision with notes)
      (:prefix-map ("X" . "capture")
       :desc "Inbox task"        "i" (cmd! (org-capture nil "i"))
       :desc "Someday/maybe"     "s" (cmd! (org-capture nil "s"))
       :desc "Weekly review"     "w" (cmd! (org-capture nil "w"))
       :desc "Monthly review"    "m" (cmd! (org-capture nil "m"))
       :desc "Quarterly review"  "q" (cmd! (org-capture nil "q"))
       :desc "Annual review"     "y" (cmd! (org-capture nil "y"))))
```

#### 9.3.11 Visual config

This block sets the theme, font, and visual polish. Edit theme name or font size here to taste — these are the lines you'll come back to most.

```elisp
;; ──────────────────────────────────────────────────────────
;; Theme
;; ──────────────────────────────────────────────────────────
(setq doom-theme 'doom-tokyo-night)

;; ──────────────────────────────────────────────────────────
;; Fonts — JetBrains Mono everywhere
;; ──────────────────────────────────────────────────────────
;; doom-font           — primary monospace face
;; doom-variable-pitch — used for prose (set to mono on purpose, per user pref)
;; doom-serif-font     — used by some org faces; same family for consistency
(setq doom-font            (font-spec :family "JetBrains Mono" :size 14 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "JetBrains Mono" :size 14)
      doom-serif-font    (font-spec :family "JetBrains Mono" :size 14 :weight 'regular))

;; Small UI niceties
(setq-default line-spacing 0.15)

;; ──────────────────────────────────────────────────────────
;; org-modern — modern visual styling for org-mode
;; ──────────────────────────────────────────────────────────
(use-package! org-modern
  :after org
  :hook (org-mode . org-modern-mode)
  :hook (org-agenda-finalize . org-modern-agenda)
  :config
  (setq org-modern-star      ["◉" "○" "✸" "✿" "✤" "✜" "◆"]
        org-modern-list      '((?- . "•") (?+ . "‣") (?* . "▸"))
        org-modern-checkbox  '((?X . "☑") (?- . "▣") (?\s . "☐"))
        org-modern-table-vertical 1
        org-modern-table-horizontal 0.2
        org-modern-block-fringe nil
        org-modern-todo-faces
        '(("TODO" :foreground "#ff6c6b" :weight bold)
          ("STRT" :foreground "#ECBE7B" :weight bold)
          ("WAIT" :foreground "#a9a1e1" :weight bold)
          ("DONE" :foreground "#98be65" :weight bold)
          ("KILL" :foreground "#5B6268" :weight bold))))

;; Slightly larger headings in org files for visual hierarchy
(custom-set-faces!
  '(org-document-title :height 1.6 :weight bold)
  '(outline-1 :height 1.3 :weight bold)
  '(outline-2 :height 1.2 :weight bold)
  '(outline-3 :height 1.1 :weight bold))
```

Notes:
- The `doom-tokyo-night` theme ships with `doom-themes` (bundled by Doom). No extra package needed.
- The `:hook (org-agenda-finalize . org-modern-agenda)` line styles the agenda view as well as plain org buffers.
- `org-modern-todo-faces` colors match the TODO keywords defined in Section 9.3.1. If you rename a keyword, update both blocks.
- If JetBrains Mono is not installed, Emacs falls back to a default monospace font and logs a warning. The user must install the font at the OS level — Emacs cannot install fonts itself.

---

## 10. Initial Files to Create

### 10.1 `~/org/inbox.org`

```org
#+title: Inbox
#+filetags: :inbox:

* Notes
Capture quick one-off tasks here with =SPC X i=.
Process during weekly review: either complete, link to a project, or move to someday.org.
```

### 10.2 `~/org/someday.org`

```org
#+title: Someday / Maybe
#+filetags: :someday:

* About
Parked project ideas. Review during quarterly review.
After 3–4 quarters of no movement, an item should be honestly deleted.
```

### 10.3 Example PPV trio

Create these as starter content so the user can see the link structure working.

**`~/org/goals/example-goal.org`** — created by `SPC X` → `g` capture, but seed manually as:
```org
:PROPERTIES:
:ID:       <generated-uuid>
:END:
#+title: Wear a shirt off the rack
#+filetags: :goal:

* Why this matters
A small, tangible marker of being comfortable in my body.

* Pillars supporting this goal
```

**`~/org/pillars/fitness.org`**:
```org
:PROPERTIES:
:ID:       <generated-uuid>
:END:
#+title: Fitness
#+filetags: :pillar:

* Value goal
[[id:<example-goal-uuid>][Wear a shirt off the rack]]

* Guiding principles
- Consistency over intensity.
- Track what matters, ignore the rest.

* Projects

* Pillar-level tasks
```

**`~/org/projects/strength-program-q2.org`**:
```org
:PROPERTIES:
:ID:       <generated-uuid>
:END:
#+title: Strength program Q2 2026
#+filetags: :project:

* Pillar
[[id:<fitness-uuid>][Fitness]]

* Definition of done
Completed 12 weeks of the program with at least 80% session attendance.

* Tasks
** TODO Book gym induction
   SCHEDULED: <2026-05-27 Wed>
** TODO Print program PDF
** STRT Week 1 sessions
   SCHEDULED: <2026-05-26 Tue>

* Notes

* Archive
```

Claude Code should generate fresh UUIDs (Emacs will do this automatically when creating via the capture templates; for manual seeding, use `org-id-new` or any UUID v4 generator).

### 10.4 Review templates

Create in `~/.config/doom/templates/`:

**`weekly-review.org`**:
```org
#+title: Weekly Review %<%Y-W%V>
#+date: %<%Y-%m-%d>
#+filetags: :review:weekly:

* Past Week

** Time spent
#+BEGIN: clocktable :scope agenda :block lastweek :maxlevel 3 :compact t
#+END:

** Accomplishments
-

** Disappointments
-

** Highlights & struggles
-

** Lessons learned
-

* Cleanup
- [ ] Inbox to zero
- [ ] Calendar 3-week look-ahead reviewed
- [ ] DONE tasks archived in each active project
- [ ] Re-read guiding principles for each pillar

* Project review
For each active project: direction / progress / next-week tasks.

** [Project A]
   - Direction:
   - Progress:
   - Next week:

* Next Week Plan

** Top 3 priorities
1.
2.
3.

** Other commitments
-

%?
```

**`monthly-review.org`**:
```org
#+title: Monthly Review %<%Y-%m>
#+date: %<%Y-%m-%d>
#+filetags: :review:monthly:

* The Month in Review

** Breakthroughs
-

** Discoveries
-

** Notable activities
-

** Improvements going forward
-

** Time spent by pillar
#+BEGIN: clocktable :scope agenda :block thismonth :maxlevel 2 :compact t
#+END:

* Pillar review
Walk each pillar node. Refine principles, retire stale projects, spawn new ones if needed.

** [Pillar 1]
   - Still aligned with its value goal?
   - Adjustments:

* Performance review
Look at daily and weekly review notes. Patterns? Bottlenecks?

* Bookkeeping
- [ ] Done (handled outside this system)

%?
```

**`quarterly-review.org`**:
```org
#+title: Quarterly Review %<%Y-Q%q>
#+date: %<%Y-%m-%d>
#+filetags: :review:quarterly:

* Process evaluation

** What's working
-

** What's not working
-

** What needs to change
-

* Pillars and value goals
Are they still the right ones?

** Value goal review
- Are these still what I want?
- Any to retire or revise?

** Pillar review
- Are these the right life domains for me right now?
- Anything missing?
- Anything to merge or split?

* Fleeting notes review
Open knowledge/fleeting/. For each:
- Promote to permanent concept note, OR
- Link into an existing concept, OR
- Delete.

* Someday list review
Open someday.org. For each item:
- Promote to active project this quarter, OR
- Keep parked, OR
- Honestly delete.

* Next quarter focus

** Theme for the quarter
-

** Top 3 outcomes
1.
2.
3.

%?
```

**`annual-review.org`**:
```org
#+title: Annual Review %<%Y>
#+date: %<%Y-%m-%d>
#+filetags: :review:annual:

* The Year in Review

** Time spent by pillar
#+BEGIN: clocktable :scope agenda :block thisyear :maxlevel 2 :compact t
#+END:

** Major accomplishments
-

** Major lessons
-

** What changed about me this year
-

* Looking at the four quarterly reviews
Open each quarterly review. Patterns? Trajectory?

* Next year

** Value goals for next year

** Pillars

** Theme of the year

%?
```

### 10.5 Cheatsheet

Create `~/org/CHEATSHEET.org`:

```org
#+title: Life OS Cheatsheet

* Capture
| Binding   | Action                                      |
|-----------+---------------------------------------------|
| SPC X i   | Quick inbox task                            |
| SPC X s   | Someday / maybe                             |
| SPC n c   | Roam capture (goal/pillar/project/concept…) |
| SPC n r d t | Today's daily journal entry               |

* Reviews
| Binding | Action            |
|---------+-------------------|
| SPC X w | Weekly review     |
| SPC X m | Monthly review    |
| SPC X q | Quarterly review  |
| SPC X y | Annual review     |

* Dashboards
| Binding   | Action                    |
|-----------+---------------------------|
| SPC A D   | Daily dashboard           |
| SPC A W   | Weekly dashboard          |
| SPC A M   | Monthly dashboard         |
| SPC A Q   | Quarterly dashboard       |
| SPC A Y   | Annual dashboard          |
| SPC o c   | Month grid (calfw)        |
| SPC o a   | Standard org-agenda menu  |

* Inside the agenda
| Key             | Action                       |
|-----------------+------------------------------|
| j / k           | Move down / up               |
| S-→ / S-←       | Reschedule +1d / −1d         |
| S-↑ / S-↓       | Change priority              |
| t               | Cycle TODO state             |
| r               | Refresh                      |
| q               | Quit                         |

* Inside an org file
| Key         | Action                          |
|-------------+---------------------------------|
| C-c C-t     | Set TODO state                  |
| C-c C-s     | Schedule                        |
| C-c C-d     | Deadline                        |
| C-c C-x C-a | Archive subtree                 |
| C-c C-x C-i | Clock in                        |
| C-c C-x C-o | Clock out                       |
| C-c C-l     | Insert link (incl. roam id)     |
| SPC n r i   | Insert roam link                |
| SPC n r b   | Toggle roam backlinks buffer    |

* Workflow

** Daily
1. SPC A D — open daily dashboard.
2. Work through tasks; clock in (C-c C-x C-i) when starting.
3. Capture interruptions with SPC X i or SPC n r d t.
4. End of day: ~5 min review (just glance at the dashboard, plan tomorrow).

** Weekly (Sunday)
1. SPC X w — open this week's review file.
2. Run clocktable (C-c C-c on the line).
3. Fill in reflection sections.
4. Process inbox to zero.
5. Walk projects via roam, evaluate.
6. Archive DONE tasks (C-c C-x C-a) in each active project.

** Monthly / Quarterly / Annual
Follow the prompts in the respective template.
```

---

## 11. Post-Installation Verification Checklist

After all phases are complete, verify:

- [ ] `doom doctor` reports no errors.
- [ ] `doom sync` runs cleanly and re-tangles `config.org` → `config.el` without errors.
- [ ] Editing `config.org` and running `M-x org-babel-tangle` updates `config.el` without errors.
- [ ] Opening Emacs takes the user to the dashboard without errors.
- [ ] `SPC n c` shows the roam capture menu with all PPV + vault templates.
- [ ] Creating a new project via `SPC n c` → `r` prompts for a pillar and prefills the link.
- [ ] `SPC o c` opens the calfw month calendar showing scheduled org tasks.
- [ ] `SPC A D` opens the daily dashboard with tasks grouped by category/pillar.
- [ ] `SPC X i` captures into `~/org/inbox.org`.
- [ ] `SPC X w` creates a new weekly review file with all prompts.
- [ ] Inside a weekly review file, `C-c C-c` on the clocktable line populates it.
- [ ] Marking a task DONE inserts a CLOSED timestamp in `:LOGBOOK:`.
- [ ] `C-c C-x C-a` archives a subtree to a `* Archive` heading in the same file.
- [ ] Vim motions (`h j k l`, `i`, `o`, `dd`, etc.) work everywhere.
- [ ] `doom-tokyo-night` theme is active and JetBrains Mono is rendering throughout.
- [ ] org-modern is active in org buffers (visible by styled bullets, table borders, and todo keyword pill-shapes).
- [ ] org-modern-agenda is active in `SPC o a` and the review dashboards (dates render as pill-shaped labels).

---

## 12. Cheatsheet

See Section 10.5 — installed as `~/org/CHEATSHEET.org`.

---

## 13. Out of Scope (Future Phases)

The following are intentionally deferred. The architecture should not preclude them, but Claude Code should NOT implement them in this pass:

- **Pipelines** — recurring workflow templates (YouTube-style production flows). Design idea: a `pipelines/` folder of roam nodes, each representing a workflow with a fixed sequence of TODO templates that can be instantiated.
- **Mobile sync** — Beorg or Organice via Syncthing/Git.
- **Web dashboard** — read-only browser view of agenda data.
- **Org-roam-ui graph** — optional; package is installed but not wired into a binding here.
- **Bookkeeping** — user handles separately.
- **Cross-device sync** — out of scope; user is on a single machine for now.

---

## Appendix A: Notes for Claude Code

- The user values **stability over novelty**. If a package is unmaintained but works, prefer it over a newer alternative that requires more configuration. (Specifically: calfw is the safe choice for the month grid even though `org-timeblock` is newer.)
- The user is new to Emacs but very comfortable with vim — never disable evil-mode or suggest non-evil bindings.
- **Literate config convention:** edit `~/.config/doom/config.org`, never `config.el`. The generated `config.el` is overwritten by every tangle. When adding a new elisp block, place it under the most relevant org heading and rely on the file-level `#+property: header-args:emacs-lisp :tangle yes` to tangle it (no per-block `:tangle yes` needed). Prefix each new section with a one- or two-line prose explanation so the file reads as documentation, not just code.
- If anything in this PRD conflicts with current Doom defaults, prefer the PRD but explain the conflict.
- If a verification step fails, **stop and report** rather than continuing to subsequent phases.

## Appendix B: Useful References

- Doom Emacs documentation: https://docs.doomemacs.org/
- Org-roam v2 manual: https://www.orgroam.com/manual.html
- org-super-agenda: https://github.com/alphapapa/org-super-agenda
- calfw: https://github.com/kiwanami/emacs-calfw
- August Bradley's Life OS framework (Notion original): https://www.youtube.com/c/AugustBradley
