(setq initial-buffer-choice (lambda () (find-file "~/org/inbox.org")))

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
  ;; Catppuccin Macchiato palette:
  ;;   green   #a6da95   blue   #8aadf4   yellow #eed49f
  ;;   red     #ed8796   overlay0 #6e738d (muted)
  (setq org-todo-keyword-faces
        '(("TODO" . (:foreground "#a6da95" :weight bold))   ; green — to do
          ("STRT" . (:foreground "#8aadf4" :weight bold))   ; blue  — in progress
          ("WAIT" . (:foreground "#eed49f" :weight bold))   ; yellow — blocked
          ("DONE" . (:foreground "#6e738d" :weight normal)) ; muted — out of sight
          ("KILL" . (:foreground "#ed8796" :weight bold)))) ; red — dropped

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
        org-fold-catch-invisible-edits 'smart
        org-ellipsis " ▾"))                 ; folded-heading marker

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

;; ──────────────────────────────────────────────────────────
;; Helper: prompt for a roam node filtered by tag, return [[id:..]] link.
;;
;; Used inside the capture templates below via %(...) so capture-time
;; produces a real org-roam link (not just plain text). Backlinks pick
;; the new node up automatically once captured.
;;
;; If no nodes with the requested tag exist yet (e.g. capturing the
;; very first Pillar before any Goal exists), it inserts an empty
;; string rather than erroring — you can add the link later with
;; SPC n r i.
;; ──────────────────────────────────────────────────────────
(defun life-os/roam-link-by-tag (tag)
  "Prompt for a roam node tagged TAG and return its [[id:..]] link string."
  (require 'cl-lib)
  (let* ((nodes (cl-remove-if-not
                 (lambda (n) (member tag (org-roam-node-tags n)))
                 (org-roam-node-list)))
         (titles (mapcar #'org-roam-node-title nodes)))
    (if (null nodes)
        (progn
          (message "No org-roam nodes tagged :%s: yet — link later with SPC n r i." tag)
          "")
      (let* ((choice (completing-read (format "Linked %s: " tag)
                                      titles nil t))
             (node (cl-find choice nodes
                            :key #'org-roam-node-title
                            :test #'equal)))
        (if node
            (format "[[id:%s][%s]]"
                    (org-roam-node-id node)
                    (org-roam-node-title node))
          "")))))

;; ──────────────────────────────────────────────────────────
;; Roam capture templates
;;
;; Hierarchy enforced via :filetags and an explicit parent link in
;; the new file. The user picks the parent at capture time via the
;; life-os/roam-link-by-tag helper above.
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
                              "#+title: ${title}\n#+filetags: :pillar:\n\n* Value goal\n%(life-os/roam-link-by-tag \"goal\")\n\n* Guiding principles\n\n* Projects\n\n* Pillar-level tasks\n")
           :unnarrowed t)

          ("r" "Project" plain
           "%?"
           :target (file+head "projects/${slug}.org"
                              "#+title: ${title}\n#+filetags: :project:\n\n* Pillar\n%(life-os/roam-link-by-tag \"pillar\")\n\n* Definition of done\n\n* Tasks\n\n* Notes\n")
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

;; ──────────────────────────────────────────────────────────
;; Fix: keep the roam :ID: drawer at the TOP of new files.
;;
;; THE CROSS-MACHINE DISCREPANCY (CLAUDE.md). On a brand-new
;; `file+head' capture, org-roam sets its insert point to
;; (point-max) — see org-roam-capture--setup-target-location, the
;; `(setq p (point-max))' line. For our templates that end with
;; headings (Goal/Pillar/Project/Literature/Meeting), point-max sits
;; *inside the last subtree*, so `org-entry-put' drops the :ID: into
;; that last heading — i.e. the bottom of the file. Templates with no
;; headings (Concept/Fleeting) land at the top by luck. Win11 puts it
;; at the top (older org-roam where p was point-min), hence the split.
;;
;; A second flavour of the same bug bites the dailies (SPC n r d …).
;; Those use an `entry'-type template, and for entry captures org-roam
;; stamps a *fresh* :ID: on the new `* HH:MM' heading every single time
;; (via org-roam-capture--create-id-for-entry) — so each daily capture
;; appends yet another ID at the bottom and every log line becomes its
;; own node. We want the day FILE to be the one node and the timestamp
;; lines to stay plain.
;;
;; Shared fix below: `life-os/roam-lift-id-to-top' cuts a stray ":ID:"
;; line from wherever org-roam left it and re-creates it as a single
;; file-level drawer at the very top. Two hooks call it — one for
;; ordinary file nodes (only on a brand-new file) and one for dailies
;; (every capture, to strip the per-entry ID). Both are idempotent: a
;; no-op when the ID is already up top, so they're safe on both
;; machines and survive a future `doom upgrade'.
;; ──────────────────────────────────────────────────────────
(defun life-os/roam-lift-id-to-top (id)
  "Ensure ID lives in a file-level :PROPERTIES: drawer at the top.
Cut any stray `:ID: ID' line org-roam left below the first heading
(plus its emptied drawer) and re-create ID at the file level.  A
no-op when ID is already the top-level file ID."
  (when (and id (derived-mode-p 'org-mode))
    (org-with-wide-buffer
     (unless (equal id (org-entry-get (point-min) "ID"))
       ;; Cut the stray ":ID: <id>" line wherever org-roam put it…
       (goto-char (point-min))
       (when (re-search-forward
              (format "^[ \t]*:ID:[ \t]+%s[ \t]*\n" (regexp-quote id))
              nil t)
         (let ((beg (match-beginning 0)))
           (delete-region beg (match-end 0))
           ;; …and tidy the now-empty :PROPERTIES:/:END: pair.
           (save-excursion
             (goto-char beg)
             (forward-line -1)
             (when (looking-at-p
                    "^[ \t]*:PROPERTIES:[ \t]*\n[ \t]*:END:[ \t]*\n")
               (delete-region (point) (progn (forward-line 2) (point)))))))
       ;; …then (re-)create it as a file-level property at the top,
       ;; unless the file already carries one (later dailies captures).
       (unless (org-entry-get (point-min) "ID")
         (org-entry-put (point-min) "ID" id))))))

(defun life-os/roam-dailies-buffer-p ()
  "Non-nil when the current buffer's file lives under the dailies dir."
  (when-let* ((file (buffer-file-name (buffer-base-buffer)))
              (dir (and (bound-and-true-p org-roam-dailies-directory)
                        (expand-file-name org-roam-dailies-directory
                                          org-roam-directory))))
    (file-in-directory-p file dir)))

(defun life-os/roam-id-to-top ()
  "Hoist a brand-new *file* node's :ID: to a top-level drawer."
  (when (and (org-roam-capture--get :new-file)     ; only brand-new files
             (not (life-os/roam-dailies-buffer-p))); dailies handled below
    (life-os/roam-lift-id-to-top
     (org-roam-node-id org-roam-capture--node))))

(defun life-os/roam-daily-file-as-node ()
  "Keep ONE :ID: on the day file instead of one per dailies entry.
Strips the per-entry ID org-roam just stamped and ensures a single
file-level ID up top, so the day is the node and the timestamp lines
stay plain."
  (when (life-os/roam-dailies-buffer-p)
    (life-os/roam-lift-id-to-top
     (org-roam-node-id org-roam-capture--node))))

(after! org-roam
  (add-hook 'org-roam-capture-new-node-hook #'life-os/roam-id-to-top)
  (add-hook 'org-roam-capture-new-node-hook #'life-os/roam-daily-file-as-node))

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
                                            (concat org-directory "projects/")))
                          "Notes")
           "* %?\n  %U"
           :empty-lines 1)

          ;; ── Reviews are appended in the Review block below
          )))

;; ──────────────────────────────────────────────────────────
;; Org-roam dailies capture
;;
;; Single template only → org-capture skips the template-selection
;; menu and drops straight into the capture buffer. Add any tags
;; yourself in the entry body.
;; ──────────────────────────────────────────────────────────
(after! org-roam
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d %A>\n#+filetags: :daily:\n")))))

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

;; ──────────────────────────────────────────────────────────
;; Custom agenda commands
;;
;; D = Daily dashboard           (~5 min review)
;; W = Weekly dashboard          (~45–60 min)
;; M = Monthly dashboard         (~60–90 min)
;; Q = Quarterly dashboard       (~2–3 hr)
;; Y = Annual dashboard          (~half day)
;;
;; GOTCHA: Doom sets a GLOBAL `org-agenda-start-day' of "-3d", so any
;; `agenda' block that omits it starts 3 days early (Daily showed the
;; 29th, not today). Every block below sets it explicitly; nil = today.
;; Full story in CLAUDE.md → "Gotchas".
;; ──────────────────────────────────────────────────────────
(after! org-agenda
  (setq org-agenda-custom-commands
        '(("D" "Daily dashboard"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-start-day nil)   ; today (not Doom's -3d)
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
                     (org-agenda-start-day "-7d")  ; the 7 days ending yesterday
                     (org-agenda-start-with-log-mode '(closed))
                     (org-agenda-overriding-header "📊 PAST WEEK")))
            (agenda ""
                    ((org-agenda-span 7)
                     (org-agenda-start-day nil)    ; today + next 6 days (was "+1d",
                                                   ; which skipped today entirely)
                     (org-agenda-overriding-header "🔮 NEXT 7 DAYS")))
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

;; ──────────────────────────────────────────────────────────
;; Calfw — month-grid calendar populated from org-agenda
;;
;; Entry point: M-x calfw-org-open-calendar (bound to SPC o c in Phase 7).
;;
;; In the calendar buffer:
;;   n / p          next / previous day
;;   N / P          next / previous week
;;   M-n / M-p      next / previous month
;;   t              jump to today
;;   RET            jump to the org file/heading under cursor
;;   q              quit
;; ──────────────────────────────────────────────────────────
(use-package! calfw
  :commands (calfw-open-calendar-buffer))

(use-package! calfw-org
  ;; Note: do NOT add :after calfw here. Doing so defers Doom's autoload
  ;; setup for these commands until calfw is loaded, which means
  ;; M-x calfw-org-open-calendar (and the SPC o c binding) won't work
  ;; until something else loads calfw first. calfw-org.el itself does
  ;; (require 'calfw) at its top, so the dependency is handled.
  :commands (calfw-org-open-calendar
             calfw-org-create-source)
  :config
  ;; Let calfw-org's own keybindings win in org buffers reached from the cal.
  (setq calfw-org-overwrite-default-keybinding t))

;; Nicer Unicode box-drawing characters for the calendar grid.
;; Defaults are ASCII (+, -, |) which look noisy. These render as
;; smooth heavy lines in any decent monospace font.
(after! calfw
  (setq calfw-fchar-junction         ?╋
        calfw-fchar-vertical-line    ?┃
        calfw-fchar-horizontal-line  ?━
        calfw-fchar-left-junction    ?┣
        calfw-fchar-right-junction   ?┫
        calfw-fchar-top-junction     ?┯
        calfw-fchar-top-left-corner  ?┏
        calfw-fchar-top-right-corner ?┓))

;; ──────────────────────────────────────────────────────────
;; Calfw faces — Catppuccin Macchiato
;;
;; Out of the box calfw uses hard primary blues/reds that clash with
;; the Catppuccin theme. Remap every calfw face to the Macchiato
;; palette so the calendar matches the rest of Emacs.
;;
;; Palette (Macchiato):
;;   base    #24273a   surface0 #363a4f   surface1 #494d64
;;   overlay0 #6e738d  subtext0 #a5adcb   text     #cad3f5
;;   blue    #8aadf4   lavender #b7bdf8    teal     #8bd5ca
;;   green   #a6da95   yellow   #eed49f    peach    #f5a97f
;;   red     #ed8796   mauve    #c6a0f6
;;
;; custom-set-faces! is applied after the theme loads, so these win.
;; ──────────────────────────────────────────────────────────
(custom-set-faces!
  ;; Big month title at the top.
  '(calfw-title-face        :foreground "#c6a0f6" :weight bold :height 2.0)
  ;; Weekday header row (Mon Tue Wed …).
  '(calfw-header-face       :foreground "#b7bdf8" :weight bold)
  ;; Weekend column tints.
  '(calfw-sunday-face       :foreground "#ed8796" :weight bold)
  '(calfw-saturday-face     :foreground "#8aadf4" :weight bold)
  '(calfw-holiday-face      :foreground "#f5a97f")
  ;; The box-drawing grid — keep it quiet so events stand out.
  '(calfw-grid-face         :foreground "#494d64")
  ;; Day number in each cell, and event/period content.
  '(calfw-day-title-face    :foreground "#a5adcb")
  '(calfw-default-day-face  :foreground "#cad3f5" :weight bold)
  ;; Event text: neutral (the time prefix is the accent — see transformer below).
  '(calfw-default-content-face :foreground "#cad3f5")
  '(calfw-periods-face      :foreground "#8bd5ca")
  ;; Today: subtle surface highlight + a solid blue day number.
  '(calfw-today-face        :background "#363a4f")
  '(calfw-today-title-face  :foreground "#24273a" :background "#8aadf4" :weight bold)
  ;; Days spilling in from adjacent months, annotations, toolbar.
  '(calfw-disable-face      :foreground "#6e738d")
  '(calfw-annotation-face   :foreground "#8087a2")
  '(calfw-toolbar-face            :foreground "#6e738d" :background "#1e2030")
  '(calfw-toolbar-button-off-face :foreground "#6e738d")
  '(calfw-toolbar-button-on-face  :foreground "#8aadf4" :weight bold))

;; ──────────────────────────────────────────────────────────
;; No background "blob" on entries
;;
;; calfw colors each agenda item with its SOURCE color (default
;; "Seagreen4"), compositing it into a faint :foreground AND
;; :background — the green text + green blob behind every entry.
;;
;; We can't just pass a nil source color: the periods code path
;; (`calfw--source-period-bgcolor-get') feeds the color straight to
;; `color-name-to-rgb', so nil crashes rendering. Instead, override
;; the two face-deriving functions to ignore the source color and
;; return the plain DEFAULT-FACE the callers already pass
;; (`calfw-default-content-face' / `calfw-periods-face' — both styled
;; above). Result: theme-coherent text, no source-derived colors.
;; ──────────────────────────────────────────────────────────
(after! calfw
  (defadvice! life-os/calfw-plain-content-face (_text default-face)
    "Ignore the per-source color; use the plain content face (no bg blob)."
    :override #'calfw--render-get-face-content
    default-face)

  (defadvice! life-os/calfw-plain-period-face (_text default-face)
    "Ignore the per-source color; use the plain period face."
    :override #'calfw--render-get-face-period
    default-face))

;; ──────────────────────────────────────────────────────────
;; Accent the time
;;
;; calfw-org prefixes timed entries with "HH:MM " but leaves it the
;; same face as the rest of the entry. Wrap the default formatter and
;; tint that leading time peach + bold so the start time pops.
;; ──────────────────────────────────────────────────────────
(defun life-os/calfw-org-summary-format (item)
  "Like `calfw-org-summary-format', but accent the leading HH:MM time."
  (let ((line (calfw-org-summary-format item)))
    (when (and (stringp line)
               (string-match "\\`[0-9]\\{2\\}:[0-9]\\{2\\} " line))
      (add-face-text-property (match-beginning 0) (match-end 0)
                              '(:foreground "#f5a97f" :weight bold) ; peach
                              nil line))
    line))

(after! calfw-org
  (setq calfw-org-schedule-summary-transformer
        #'life-os/calfw-org-summary-format))

;; ──────────────────────────────────────────────────────────
;; Evil — let calfw's single-key navigation through
;;
;; `calfw-calendar-mode' is a hand-rolled major mode (NOT
;; define-derived-mode): it sets `major-mode' by hand and only runs
;; its own `calfw-calendar-mode-hook', never `after-change-major-
;; mode-hook'. So evil never initializes a sensible state for it,
;; falls back to normal state, and its keymap shadows calfw's
;; single-key bindings (n p N P d w m t g q) — the buffer feels
;; frozen. (Whether evil-collection happens to patch this is load-
;; order luck, which is why it bites on Linux but not Windows.)
;;
;; Force the buffer into evil "emacs" state so every key reaches
;; calfw's own keymap. `evil-set-initial-state' covers any later
;; re-initialization; the hook covers the initial open.
;; ──────────────────────────────────────────────────────────
(after! calfw
  (evil-set-initial-state 'calfw-calendar-mode 'emacs)
  (add-hook 'calfw-calendar-mode-hook #'evil-emacs-state)

  ;; ────────────────────────────────────────────────────────
  ;; Fit the grid to the full window width on open
  ;;
  ;; calfw sizes the grid from the window at *creation* time, before
  ;; switch-to-buffer has grown the window to full width — so it opens
  ;; at ~2/3 width until you press `g'. Re-render once on the next idle
  ;; tick, when the window has settled at its final size.
  ;;
  ;; NOTE: the buffer is passed as a *timer argument*, not captured in
  ;; a closure — config.el is tangled without a lexical-binding cookie,
  ;; so a closed-over `buf' would be void at timer time.
  ;; ────────────────────────────────────────────────────────
  (defadvice! life-os/calfw-fit-to-window (&rest _)
    "Refresh the calendar after the window reaches its final width."
    :after #'calfw-open-calendar-buffer
    (run-with-idle-timer
     0 nil
     (lambda (b)
       (when (and (buffer-live-p b)
                  (eq (buffer-local-value 'major-mode b) 'calfw-calendar-mode))
         (with-current-buffer b
           (calfw-refresh-calendar-buffer nil))))
     (current-buffer))))

;; ──────────────────────────────────────────────────────────
;; Pre-build agenda buffers before opening calfw
;;
;; calfw-org warns "open org-agenda buffer first" and skips TODO-
;; keyword fontification when `org-todo-keywords-for-agenda' is unset
;; — which it is until org-agenda has been built once. Populate it up
;; front so the calendar colors TODO keywords and the warning is gone.
;; ──────────────────────────────────────────────────────────
(defadvice! life-os/calfw-prep-agenda (&rest _)
  "Populate `org-todo-keywords-for-agenda' before calfw renders."
  :before #'calfw-org-open-calendar
  (org-agenda-prepare-buffers (org-agenda-files)))

;; ──────────────────────────────────────────────────────────
;; Review system — find-or-create review files from templates
;; ──────────────────────────────────────────────────────────

(defun life-os/--current-quarter ()
  "Return the calendar quarter (1–4) for today as an integer."
  (1+ (/ (1- (string-to-number (format-time-string "%m"))) 3)))

(defun life-os/--make-review-file (file template-name &optional extra-subs)
  "Create FILE from ~/.config/doom/templates/TEMPLATE-NAME if missing.
Expands org-style =%<...>= time codes. EXTRA-SUBS is an alist of
=(literal . replacement)= pairs applied after time expansion (used to
substitute =%q= for the current quarter, since =%q= is not a valid
=format-time-string= code)."
  (unless (file-exists-p file)
    (make-directory (file-name-directory file) t)
    (let ((tmpl (expand-file-name template-name "~/.config/doom/templates/")))
      (with-temp-file file
        (insert-file-contents tmpl)
        ;; Expand %<...> format-time-string codes.
        (goto-char (point-min))
        (while (re-search-forward "%<\\([^>]+\\)>" nil t)
          (replace-match (format-time-string (match-string 1)) t t))
        ;; Apply any extra literal substitutions.
        (dolist (sub extra-subs)
          (goto-char (point-min))
          (while (search-forward (car sub) nil t)
            (replace-match (cdr sub) t t)))))))

(defun life-os/open-weekly-review ()
  "Open this ISO week's review file, creating from template if missing."
  (interactive)
  (let ((file (expand-file-name
               (format-time-string "~/org/reviews/weekly/%Y-W%V.org"))))
    (life-os/--make-review-file file "weekly-review.org")
    (find-file file)))

(defun life-os/open-monthly-review ()
  "Open this month's review file, creating from template if missing."
  (interactive)
  (let ((file (expand-file-name
               (format-time-string "~/org/reviews/monthly/%Y-%m.org"))))
    (life-os/--make-review-file file "monthly-review.org")
    (find-file file)))

(defun life-os/open-quarterly-review ()
  "Open this quarter's review file, creating from template if missing."
  (interactive)
  (let* ((q (life-os/--current-quarter))
         (qs (number-to-string q))
         (file (expand-file-name
                (format "~/org/reviews/quarterly/%s-Q%s.org"
                        (format-time-string "%Y") qs))))
    (life-os/--make-review-file file "quarterly-review.org"
                                `(("%q" . ,qs)))
    (find-file file)))

(defun life-os/open-annual-review ()
  "Open this year's review file, creating from template if missing."
  (interactive)
  (let ((file (expand-file-name
               (format-time-string "~/org/reviews/annual/%Y.org"))))
    (life-os/--make-review-file file "annual-review.org")
    (find-file file)))

;; ──────────────────────────────────────────────────────────
;; Leader-key bindings — Life OS
;; ──────────────────────────────────────────────────────────
;; ──────────────────────────────────────────────────────────
;; Agenda navigation — force j/k to mean "down/up" everywhere in the
;; agenda, including on org-super-agenda section header lines.
;;
;; Super-agenda sets `org-super-agenda-header-map' as a `keymap' /
;; `local-map' text property on each group header (e.g. "📥 Inbox").
;; That map is a copy of `org-agenda-mode-map' where j = goto-date,
;; k = capture — and because text-property keymaps win over buffer-
;; local evil bindings, j/k stop being motion keys when point is on
;; a header. We rebind both in that map, plus in the regular agenda
;; map for completeness.
;; ──────────────────────────────────────────────────────────
(map! :map org-agenda-mode-map
      :nm "j" #'org-agenda-next-line
      :nm "k" #'org-agenda-previous-line)

(after! org-super-agenda
  (define-key org-super-agenda-header-map "j" #'org-agenda-next-line)
  (define-key org-super-agenda-header-map "k" #'org-agenda-previous-line))

(map! :leader
      ;; Calendar — bind SPC o c directly (simpler than :prefix wrapper).
      :desc "Calfw month calendar" "o c" #'calfw-org-open-calendar

      ;; Custom agenda dashboards
      (:prefix-map ("A" . "agenda dashboards")
       :desc "Daily"     "D" (cmd! (org-agenda nil "D"))
       :desc "Weekly"    "W" (cmd! (org-agenda nil "W"))
       :desc "Monthly"   "M" (cmd! (org-agenda nil "M"))
       :desc "Quarterly" "Q" (cmd! (org-agenda nil "Q"))
       :desc "Annual"    "Y" (cmd! (org-agenda nil "Y")))

      ;; Captures (X for eXpress capture, to avoid collision with notes)
      (:prefix-map ("X" . "capture")
       :desc "Inbox task"        "i" (cmd! (org-capture nil "i"))
       :desc "Someday / maybe"   "s" (cmd! (org-capture nil "s"))
       :desc "Weekly review"     "w" #'life-os/open-weekly-review
       :desc "Monthly review"    "m" #'life-os/open-monthly-review
       :desc "Quarterly review"  "q" #'life-os/open-quarterly-review
       :desc "Annual review"     "y" #'life-os/open-annual-review))

;; ──────────────────────────────────────────────────────────
;; Olivetti — centered writing column for org buffers
;; ──────────────────────────────────────────────────────────
(use-package! olivetti
  :hook (org-mode . olivetti-mode)
  :init
  (setq-default olivetti-body-width 0.65        ; 65% of frame width
                olivetti-minimum-body-width 80  ; never narrower than this
                olivetti-style nil))

;; ──────────────────────────────────────────────────────────
;; Disable line numbers in org-mode and the agenda.
;; Doom's global default is `t`; this overrides for those modes only.
;; ──────────────────────────────────────────────────────────
(add-hook! '(org-mode-hook org-agenda-mode-hook)
  (defun life-os/disable-line-numbers ()
    (display-line-numbers-mode -1)))

;; ──────────────────────────────────────────────────────────
;; Inline LaTeX preview — size and color.
;;
;; Each formula is hashed and rendered to a PNG cached under
;; `ltximg/' next to the org file. When options change, NEW formulas
;; pick up the new settings, but existing PNGs are reused. To force
;; everything to re-render, blow away the cache:
;;     M-x life-os/clear-latex-previews
;; then C-c C-x C-l once on the buffer to regenerate.
;; ──────────────────────────────────────────────────────────
(after! org
  (setq org-format-latex-options
        (plist-put org-format-latex-options :scale 1.0))      ; size
  (setq org-format-latex-options
        (plist-put org-format-latex-options :foreground "#b7bdf8")) ; lavender
  (setq org-format-latex-options
        (plist-put org-format-latex-options :background 'default)))

(defun life-os/clear-latex-previews ()
  "Delete cached LaTeX preview PNGs for the current org file."
  (interactive)
  (let* ((dir (expand-file-name "ltximg" default-directory)))
    (when (file-directory-p dir)
      (delete-directory dir t)
      (message "Cleared LaTeX preview cache at %s" dir))))

;; ──────────────────────────────────────────────────────────
;; Center display-math LaTeX previews (\\[…\\], $$…$$, \\begin{…}).
;; Inline math ($…$, \\(…\\)) is left alone.
;;
;; Org renders each formula to a PNG and shows it as an overlay at
;; the formula's location. To "center" the result we add a
;; `before-string' with `display' = (space :width PX) where PX is
;; half the leftover horizontal pixels in the window.
;; ──────────────────────────────────────────────────────────
(defun life-os/--center-org-latex-displays (&rest _)
  "Add a centering pad to display-math LaTeX preview overlays."
  (when (derived-mode-p 'org-mode)
    (dolist (ov (overlays-in (point-min) (point-max)))
      (when (eq (overlay-get ov 'org-overlay-type) 'org-latex-overlay)
        (let ((display (overlay-get ov 'display)))
          (when (and (consp display) (eq (car display) 'image))
            (save-excursion
              (goto-char (overlay-start ov))
              (when (looking-at-p
                     "[ \t]*\\(\\\\\\[\\|\\$\\$\\|\\\\begin{\\)")
                (let* ((img-w (car (image-size display t)))
                       (win-w (window-pixel-width))
                       (pad   (max 0 (/ (- win-w img-w) 2))))
                  (overlay-put ov 'before-string
                               (propertize
                                " " 'display
                                `(space :width (,pad)))))))))))))

(advice-add 'org-toggle-latex-fragment
            :after #'life-os/--center-org-latex-displays)
(advice-add 'org-latex-preview
            :after #'life-os/--center-org-latex-displays)

;; ──────────────────────────────────────────────────────────
;; Theme — Catppuccin Macchiato (matches Obsidian AnuPpuccin)
;;
;; catppuccin-flavor MUST be set before the theme is loaded.
;; Switch flavor later with: (setq catppuccin-flavor 'mocha)
;; then M-x catppuccin-reload.
;; Available flavors: 'latte (light) / 'frappe / 'macchiato / 'mocha (dark)
;; ──────────────────────────────────────────────────────────
(setq catppuccin-flavor 'macchiato)
(setq doom-theme 'catppuccin)

;; ──────────────────────────────────────────────────────────
;; Fonts — JetBrainsMono NFM everywhere
;; ──────────────────────────────────────────────────────────
;; doom-font           — primary monospace face
;; doom-variable-pitch — used for prose (set to mono on purpose, per user pref)
;; doom-serif-font     — used by some org faces; same family for consistency
(setq doom-font            (font-spec :family "JetBrainsMono NFM" :size 16 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "JetBrainsMono NFM" :size 16)
      doom-serif-font    (font-spec :family "JetBrainsMono NFM" :size 16 :weight 'regular))

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
        ;; Catppuccin Macchiato palette
        ;;   green #a6da95   blue #8aadf4   yellow #eed49f
        ;;   red   #ed8796   overlay0 #6e738d
        org-modern-todo-faces
        '(("TODO" :foreground "#a6da95" :weight bold)   ; green
          ("STRT" :foreground "#8aadf4" :weight bold)   ; blue
          ("WAIT" :foreground "#eed49f" :weight bold)   ; yellow
          ("DONE" :foreground "#6e738d" :weight normal) ; muted
          ("KILL" :foreground "#ed8796" :weight bold)))) ; red

;; Larger, heavier headings in org files for visual hierarchy.
;;
;; Org uses `org-level-1' … `org-level-8' for headlines (they nominally
;; inherit from outline-*, but Catppuccin and most themes set
;; org-level-* directly, which breaks the inheritance). So we override
;; those specifically. Available weights, lightest → heaviest:
;;   regular medium semi-bold bold extra-bold black ultra-bold
;; JetBrainsMono NFM ships all of them as real font weights.
(custom-set-faces!
  '(org-document-title :height 1.8  :weight black)
  '(org-level-1        :height 1.5  :weight extra-bold)
  '(org-level-2        :height 1.3  :weight extra-bold)
  '(org-level-3        :height 1.15 :weight extra-bold)
  '(org-level-4        :height 1.05 :weight bold)
  ;; Keep outline-* in sync for non-org buffers that use them.
  '(outline-1          :height 1.5  :weight extra-bold)
  '(outline-2          :height 1.3  :weight extra-bold)
  '(outline-3          :height 1.15 :weight extra-bold)
  '(outline-4          :height 1.05 :weight bold))

;; ──────────────────────────────────────────────────────────
;; Org table styling.
;;
;; Catppuccin sets `org-table' foreground to a muted color (and so do
;; most themes), making cell text harder to read than body text. Force
;; the bright Macchiato text color (#cad3f5) explicitly.
;;
;; Org has no built-in "first row is a header" face for the in-buffer
;; display (the `org-table-header' face only affects the window's
;; sticky header line, not the visible row). For headers, use bold
;; markers — *Header text* — and our mauve bold accent will style them.
;; ──────────────────────────────────────────────────────────
(custom-set-faces!
  '(org-table :foreground "#cad3f5"))

;; ──────────────────────────────────────────────────────────
;; Accent color for bold and italic — Catppuccin mauve (#c6a0f6).
;;
;; Setting :foreground only (no :weight / :slant override) preserves
;; the existing bold weight / italic slant — we just tint the color.
;; Affects ALL bold/italic in Emacs, not just org — mauve is gentle
;; enough that UI elements still look correct.
;; ──────────────────────────────────────────────────────────
(custom-set-faces!
  '(bold   :foreground "#c6a0f6")
  '(italic :foreground "#c6a0f6"))

;; ──────────────────────────────────────────────────────────
;; Finance directory + main journal
;; ──────────────────────────────────────────────────────────
(defvar life-os/finance-directory (file-truename "~/finance/")
  "Root directory for hledger journals.")

(defvar life-os/finance-main-journal
  (expand-file-name "main.journal" life-os/finance-directory)
  "Top-level hledger journal (includes the per-year files).")

;; ──────────────────────────────────────────────────────────
;; ledger-mode → hledger
;;
;; ledger-mode targets the `ledger' CLI by default; point it at the
;; `hledger' binary instead. `ledger-mode-should-check-version' is
;; disabled because that check only understands ledger's --version.
;; ──────────────────────────────────────────────────────────
(after! ledger-mode
  (setq ledger-binary-path "hledger"
        ledger-mode-should-check-version nil
        ;; Open report buffers in a side window, keep the journal visible.
        ledger-report-links-in-same-window nil
        ;; Re-align postings to this column on `ledger-post-align-postings'.
        ledger-post-amount-alignment-column 60)

  ;; Tell ledger-mode where the whole-ledger lives, so reports invoked
  ;; from any journal buffer operate over the full file set.
  (setenv "LEDGER_FILE" life-os/finance-main-journal))

;; hledger uses the .journal extension; also map the .hledger extension.
(add-to-list 'auto-mode-alist '("\\.journal\\'" . ledger-mode))
(add-to-list 'auto-mode-alist '("\\.hledger\\'" . ledger-mode))

;; ──────────────────────────────────────────────────────────
;; Open the main journal — SPC o f
;; ──────────────────────────────────────────────────────────
(defun life-os/open-finance-journal ()
  "Open the top-level hledger journal."
  (interactive)
  (find-file life-os/finance-main-journal))

(map! :leader
      :desc "Finance journal" "o f" #'life-os/open-finance-journal)

;; ──────────────────────────────────────────────────────────
;; Roam graph — SPC n r g
;;
;; Doom binds SPC n r g to `org-roam-graph', which shells out to the
;; Graphviz `dot' binary (not installed here) to render a static SVG.
;; We use org-roam-ui instead — an in-browser, live, interactive graph
;; that needs no external executable — so repoint the same key to it.
;; ──────────────────────────────────────────────────────────
(map! :leader
      :desc "Roam graph (UI)" "n r g" #'org-roam-ui-open)
