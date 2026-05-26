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
