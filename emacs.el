;;; emacs.el

;;; * Initialization

;;;   - Increase *Message* log max

(setq message-log-max 16384)

;;;   - Read system environment

(let ((plist (expand-file-name "~/.MacOSX/environment.plist")))
  (when (file-readable-p plist)
    (let ((dict (cdr (assq #'dict (cdar (xml-parse-file plist))))))
      (while dict
        (if (and (listp (car dict))
                 (eq 'key (caar dict)))
            (setenv (car (cddr (car dict)))
                    (car (cddr (car (cddr dict))))))
        (setq dict (cdr dict))))

    ;; Configure exec-path based on the new PATH
    (setq exec-path nil)
    (mapc #'(lambda (path)
              (add-to-list 'exec-path path))
          (nreverse (split-string (getenv "PATH") ":")))))

;;;   - Load customizations

(setq gnus-home-directory "~/Library/Mail/Gnus/") ; necessary override

(load "~/.emacs.d/settings")

;;;   - Enable disabled commands

(put 'downcase-region  'disabled nil)   ; Let upcasing work
(put 'erase-buffer     'disabled nil)
(put 'eval-expression  'disabled nil)   ; Let ESC-ESC work
(put 'narrow-to-page   'disabled nil)   ; Let narrowing work
(put 'narrow-to-region 'disabled nil)   ; Let narrowing work
(put 'set-goal-column  'disabled nil)
(put 'upcase-region    'disabled nil)   ; Let downcasing work

;;;   - Perform direct loads

(eval-when-compile
  (require 'cl))

(mapc #'require
      '(archive-region
        bbdb-autoloads
        browse-kill-ring+
        bookmark
        diminish
        edit-server
        ido
        info-look
        modeline-posn
        page-ext
        per-window-point
        pp-c-l
        recentf
        session
        tex-site
        yasnippet))

;;; * Packages

;;;   - Drew Adams

(eval-after-load "bookmark"
  '(require 'bookmark+))

(require 'compile-)
(setq compilation-message-face nil)
(eval-after-load "compile"
  '(require 'compile+))

(require 'diff-mode-)

(eval-after-load "hl-line"
  '(require 'hl-line+))

(eval-after-load "grep"
  '(progn
     (require 'grep+)
     (require 'grep-ed)))

(eval-after-load "info"
  '(progn
     (require 'easy-mmode)
     (require 'info+)))

;;;   - anything

(fset 'describe-bindings 'descbinds-anything)

(eval-after-load "anything"
  '(progn
     (require 'anything-match-plugin)
     (define-key anything-map [(alt ?v)] 'anything-previous-page)))

(setq anything-sources
      '(
        ;; Buffer:
        anything-c-source-buffers
        anything-c-source-buffer-not-found
        anything-c-source-buffers+
        ;; File:
        anything-c-source-file-name-history
        anything-c-source-files-in-current-dir
        anything-c-source-files-in-current-dir+
        anything-c-source-file-cache
        anything-c-source-locate
        anything-c-source-recentf
        anything-c-source-ffap-guesser
        anything-c-source-ffap-line
        ;; Command:
        anything-c-source-complex-command-history
        anything-c-source-extended-command-history
        anything-c-source-emacs-commands
        ;; Bookmark:
        anything-c-source-bookmarks
        anything-c-source-bookmark-set
        anything-c-source-bookmarks-ssh
        anything-c-source-bookmarks-su
        anything-c-source-bookmarks-local
        ;; Library:
        anything-c-source-elisp-library-scan
        ;; Misc:
        anything-c-source-google-suggest
        anything-c-source-mac-spotlight
        ;; System:
        anything-c-source-emacs-process))

;;;   - auctex

(defun texinfo-outline-level ()
  ;; Calculate level of current texinfo outline heading.
  (require 'texinfo)
  (save-excursion
    (if (bobp)
        0
      (forward-char 1)
      (let* ((word (buffer-substring-no-properties
                    (point) (progn (forward-word 1) (point))))
             (entry (assoc word texinfo-section-list)))
        (if entry
            (nth 1 entry)
          5)))))

;;;   - bbdb

(eval-after-load "bbdb"
  '(progn
     (require 'bbdb-to-outlook)
     (require 'bbdb-pgp)))

;;;   - css-mode

(add-to-list 'auto-mode-alist '("\\.css$" . css-mode))

;;;   - dired-x

(defvar dired-omit-regexp-orig (symbol-function 'dired-omit-regexp))

;; Omit files that Git would ignore
(defun dired-omit-regexp ()
  (let ((file (expand-file-name ".git"))
        parent-dir)
    (while (and (not (file-exists-p file))
                (progn
                  (setq parent-dir
                        (file-name-directory
                         (directory-file-name
                          (file-name-directory file))))
                  ;; Give up if we are already at the root dir.
                  (not (string= (file-name-directory file)
                                parent-dir))))
      ;; Move up to the parent dir and try again.
      (setq file (expand-file-name ".git" parent-dir)))
    ;; If we found a change log in a parent, use that.
    (if (file-exists-p file)
        (let ((regexp (funcall dired-omit-regexp-orig))
              (omitted-files (shell-command-to-string "git clean -d -x -n")))
          (if (= 0 (length omitted-files))
              regexp
            (concat
             regexp
             (if (> (length regexp) 0)
                 "\\|" "")
             "\\("
             (mapconcat
              #'(lambda (str)
                  (concat "^"
                          (regexp-quote
                           (substring str 13
                                      (if (= ?/ (aref str (1- (length str))))
                                          (1- (length str))
                                        nil)))
                          "$"))
              (split-string omitted-files "\n" t)
              "\\|")
             "\\)")))
      (funcall dired-omit-regexp-orig))))

(eval-after-load "dired"
  '(progn
     (setq dired-use-ls-dired t)

     (define-key dired-mode-map [?l] 'dired-up-directory)
     (define-key dired-mode-map [tab] 'other-window)))

;;;   - erc

(eval-when-compile
  (require 'auth-source))

(defun irc ()
  (interactive)
  (require 'auth-source)
  (erc :server "irc.freenode.net"
       :port 6667
       :nick "johnw"
       :password (funcall
                  (plist-get
                   (car (auth-source-search :host "irc.freenode.net"
                                            :user "johnw"
                                            :type 'netrc
                                            :port 6667))
                   :secret))))

(defun im ()
  (interactive)
  (require 'auth-source)
  (erc :server "localhost"
       :port 6667
       :nick "johnw"
       :password (funcall
                  (plist-get
                   (car (auth-source-search :host "bitlbee"
                                            :user "johnw"
                                            :type 'netrc
                                            :port 6667))
                   :secret))))

(defun erc-tiny-frame ()
  (interactive)
  (with-selected-frame
      (make-frame '((width                . 80)
                    (height               . 22)
                    (left-fringe          . 0)
                    (right-fringe         . 0)
                    (vertical-scroll-bars . nil)
                    (unsplittable         . t)
                    (has-modeline-p       . nil)
                    (background-color     . "grey80")
                    (minibuffer           . nil)))
    (switch-to-buffer "#emacs")
    (set (make-local-variable 'mode-line-format) nil)))

(defcustom erc-priority-people-regexp ".*"
  "Regexp that matches BitlBee users you want active notification for."
  :type 'regexp
  :group 'erc)

(defcustom erc-growl-noise-regexp
  "\\(Logging in:\\|Signing off\\|You're now away\\|Welcome back\\)"
  "This regexp matches unwanted noise."
  :type 'regexp
  :group 'erc)

;; Unless the user has recently typed in the ERC buffer, highlight the fringe
(alert-add-rule :status   '(buried visible idle)
                :severity '(moderate high urgent)
                :mode     'erc-mode
                :predicate
                #'(lambda (info)
                    (string-match (concat "\\`[^&]" erc-priority-people-regexp
                                          "@BitlBee\\'")
                                  (erc-format-target-and/or-network)))
                :persistent
                #'(lambda (info)
                    ;; If the buffer is buried, or the user has been idle for
                    ;; `alert-reveal-idle-time' seconds, make this alert
                    ;; persistent.  Normally, alerts become persistent after
                    ;; `alert-persist-idle-time' seconds.
                    (memq (plist-get info :status) '(buried idle)))
                :style 'fringe
                :continue t)

;; If the ERC buffer is not visible, tell the user through Growl
(alert-add-rule :status 'buried
                :mode   'erc-mode
                :predicate
                #'(lambda (info)
                    (let ((message (plist-get info :message))
                          (erc-message (plist-get info :data)))
                      (and erc-message
                           (not (or (string-match "^\\** *Users on #" message)
                                    (string-match erc-growl-noise-regexp
                                                  message))))))
                :style 'growl
                :append t)

(alert-add-rule :mode 'erc-mode :style 'ignore :append t)

(defun my-erc-hook (&optional match-type nick message)
  "Shows a growl notification, when user's nick was mentioned.
If the buffer is currently not visible, makes it sticky."
  (alert (or message (buffer-string)) :severity 'high
         :title (concat "ERC: " (or nick (buffer-name)))
         :data message))

(add-hook 'erc-text-matched-hook 'my-erc-hook)
(add-hook 'erc-insert-modify-hook 'my-erc-hook)

;;;   - eshell

(defun eshell-spawn-external-command (beg end)
   "Parse and expand any history references in current input."
   (save-excursion
     (goto-char end)
     (when (looking-back "&!" beg)
       (delete-region (match-beginning 0) (match-end 0))
       (goto-char beg)
       (insert "spawn "))))

(add-hook 'eshell-expand-input-functions 'eshell-spawn-external-command)

(defun ss (server)
  (interactive "sServer: ")
  (call-process "spawn" nil nil nil "ss" server))

(eval-after-load "em-unix"
  '(unintern 'eshell/rm))

;;;   - git

(setenv "GIT_PAGER" "")

(add-hook 'magit-log-edit-mode-hook
          #'(lambda ()
              (set-fill-column 72)
              (column-marker-1 72)
              (flyspell-mode)
              (orgstruct++-mode)
              (turn-on-filladapt-mode)))

(eval-after-load "magit"
  '(progn
     (require 'magit-topgit)
     (require 'rebase-mode)))

;;;   - ido

(eval-when-compile
  (defvar ido-require-match)
  (defvar ido-cur-item)
  (defvar ido-show-confirm-message)
  (defvar ido-selected)
  (defvar ido-final-text))

(defun ido-smart-select-text ()
  "Select the current completed item.  Do NOT descend into directories."
  (interactive)
  (when (and (or (not ido-require-match)
                 (if (memq ido-require-match
                           '(confirm confirm-after-completion))
                     (if (or (eq ido-cur-item 'dir)
                             (eq last-command this-command))
                         t
                       (setq ido-show-confirm-message t)
                       nil))
                 (ido-existing-item-p))
             (not ido-incomplete-regexp))
    (when ido-current-directory
      (setq ido-exit 'takeprompt)
      (unless (and ido-text (= 0 (length ido-text)))
        (let ((match (ido-name (car ido-matches))))
          (throw 'ido
                 (setq ido-selected
                       (if match
                           (replace-regexp-in-string "/\\'" "" match)
                         ido-text)
                       ido-text ido-selected
                       ido-final-text ido-text)))))
    (exit-minibuffer)))

(add-hook 'ido-minibuffer-setup-hook
          (lambda ()
            (define-key ido-file-completion-map "\C-m"
              'ido-smart-select-text)))

;;;   - modeline-posn

(size-indication-mode)

;;;   - mule

(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

(defun normalize-file ()
  (interactive)
  (goto-char (point-min))
  (whitespace-cleanup)
  (set-buffer-file-coding-system 'unix)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\r$" nil t)
      (replace-match "")))
  (set-buffer-file-coding-system 'utf-8)
  (let ((require-final-newline t))
    (save-buffer)))

;;;   - nroff-mode

(defun update-nroff-timestamp ()
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^\\.Dd ")
      (let ((stamp (format-time-string "%B %e, %Y")))
        (unless (looking-at stamp)
          (delete-region (point) (line-end-position))
          (insert stamp)
          (let (after-save-hook)
            (save-buffer)))))))

(add-hook 'nroff-mode-hook
          (function
           (lambda ()
             (add-hook 'after-save-hook 'update-nroff-timestamp nil t))))

;;;   - per-window-point

(pwp-mode)

;;;   - pp-c-l

(pretty-control-l-mode 1)

;;;   - puppet-mode

(add-to-list 'auto-mode-alist '("\\.pp$" . puppet-mode))

;;;   - session

(defun save-information ()
  (dolist (func kill-emacs-hook)
    (unless (memq func '(exit-gnus-on-exit server-force-stop))
      (funcall func)))
  (unless (eq 'listen (process-status server-process))
    (server-start)))

(run-with-idle-timer 300 t 'save-information)

;;;   - vkill

(eval-after-load "vkill"
  '(setq vkill-show-all-processes t))

;;;   - w3m

(eval-when-compile
  (defvar w3m-command))

(setq w3m-command "/opt/local/bin/w3m")

;;;   - whitespace

(remove-hook 'find-file-hooks 'whitespace-buffer)
(remove-hook 'kill-buffer-hook 'whitespace-buffer)

(defun maybe-turn-on-whitespace ()
  "Depending on the file, maybe turn on `whitespace-mode'."
  (let ((file (expand-file-name ".clean"))
        parent-dir)
    (while (and (not (file-exists-p file))
                (progn
                  (setq parent-dir
                        (file-name-directory
                         (directory-file-name
                          (file-name-directory file))))
                  ;; Give up if we are already at the root dir.
                  (not (string= (file-name-directory file)
                                parent-dir))))
      ;; Move up to the parent dir and try again.
      (setq file (expand-file-name ".clean" parent-dir)))
    ;; If we found a change log in a parent, use that.
    (when (and (file-exists-p file)
               (not (file-exists-p ".noclean"))
               (not (and buffer-file-name
                         (string-match "\\.texi$" buffer-file-name))))
      (add-hook 'write-contents-hooks
                #'(lambda ()
                    (ignore (whitespace-cleanup))) nil t)
      (whitespace-cleanup))))

(add-hook 'find-file-hooks 'maybe-turn-on-whitespace t)

;;;   - workgroups

(workgroups-mode 1)

(define-key wg-map [(control ?\\)] 'wg-switch-to-previous-workgroup)

(if (file-readable-p "~/.emacs.d/data/workgroups")
    (wg-load "~/.emacs.d/data/workgroups"))

(diminish 'workgroups-mode)

;;;   - yasnippet

(yas/initialize)
(yas/load-directory (expand-file-name "snippets/" user-emacs-directory))

;;;   - diminish (this must come last)

(diminish 'abbrev-mode)
(diminish 'auto-fill-function)
(ignore-errors
  (diminish 'yas/minor-mode))

(defadvice dired-omit-startup (after diminish-dired-omit activate)
  "Make sure to remove \"Omit\" from the modeline."
  (diminish 'dired-omit-mode))

(eval-after-load "dot-mode"
  '(diminish 'dot-mode))
(eval-after-load "filladapt"
  '(diminish 'filladapt-mode))
(eval-after-load "winner"
  '(ignore-errors (diminish 'winner-mode)))

;;;  * Post initialization

(unless (null window-system)
  (add-hook 'after-init-hook 'emacs-min)

  (add-hook 'after-init-hook 'session-initialize t)
  (add-hook 'after-init-hook 'server-start t)
  (add-hook 'after-init-hook 'edit-server-start t)

  (add-hook 'after-init-hook
            (lambda ()
              (org-agenda-list)
              (org-fit-agenda-window)
              (org-resolve-clocks)) t))

;;;  * Programming modes

;;;   - cc-mode

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.m\\'" . c-mode))
(add-to-list 'auto-mode-alist '("\\.mm\\'" . c++-mode))

(add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'" . cmake-mode))
(add-to-list 'auto-mode-alist '("\\.cmake\\'" . cmake-mode))

(defun my-c-indent-or-complete ()
  (interactive)
  (let ((class (syntax-class (syntax-after (1- (point))))))
   (if (or (bolp) (and (/= 2 class)
                       (/= 3 class)))
       (call-interactively 'indent-according-to-mode)
     (call-interactively 'company-complete-common))))

(eval-when-compile
  (defvar c-mode-base-map))

(defun my-c-mode-common-hook ()
  (company-mode 1)
  (which-function-mode 1)
  ;;(doxymacs-mode 1)
  ;;(doxymacs-font-lock)

  (define-key c-mode-base-map [return] 'newline-and-indent)

  (set (make-local-variable 'yas/fallback-behavior)
       '(apply my-c-indent-or-complete . nil))
  (define-key c-mode-base-map [tab] 'yas/expand-from-trigger-key)

  (define-key c-mode-base-map [(alt tab)] 'company-complete-common)
  (define-key c-mode-base-map [(meta ?j)] 'delete-indentation-forward)
  (define-key c-mode-base-map [(control ?c) (control ?i)]
    'c-includes-current-file)

  (set (make-local-variable 'parens-require-spaces) nil)
  (setq indicate-empty-lines t)
  (setq fill-column 72)
  (column-marker-3 80)

  (let ((bufname (buffer-file-name)))
    (when bufname
      (cond
       ((string-match "/ledger/" bufname)
        (c-set-style "ledger"))
       ((string-match "/ANSI/" bufname)
        (c-set-style "edg")
        (substitute-key-definition 'fill-paragraph 'ti-refill-comment
                                   c-mode-base-map global-map)
        (define-key c-mode-base-map [(meta ?q)] 'ti-refill-comment)))))

  (font-lock-add-keywords 'c++-mode '(("\\<\\(assert\\|DEBUG\\)("
                                       1 font-lock-warning-face t))))

(defun ti-refill-comment ()
  (interactive)
  (let ((here (point)))
    (goto-char (line-beginning-position))
    (let ((begin (point)) end
          (marker ?-) (marker-re "\\(-----\\|\\*\\*\\*\\*\\*\\)")
          (leader-width 0))
      (unless (looking-at "[ \t]*/\\*[-* ]")
        (search-backward "/*")
        (goto-char (line-beginning-position)))
      (unless (looking-at "[ \t]*/\\*[-* ]")
        (error "Not in a comment"))
      (while (and (looking-at "\\([ \t]*\\)/\\* ")
                  (setq leader-width (length (match-string 1)))
                  (not (looking-at (concat "[ \t]*/\\*" marker-re))))
        (forward-line -1)
        (setq begin (point)))
      (when (looking-at (concat "[^\n]+?" marker-re "\\*/[ \t]*$"))
        (setq marker (if (string= (match-string 1) "-----") ?- ?*))
        (forward-line))
      (while (and (looking-at "[^\n]+?\\*/[ \t]*$")
                  (not (looking-at (concat "[^\n]+?" marker-re
                                           "\\*/[ \t]*$"))))
        (forward-line))
      (when (looking-at (concat "[^\n]+?" marker-re "\\*/[ \t]*$"))
        (forward-line))
      (setq end (point))
      (let ((comment (buffer-substring-no-properties begin end)))
        (with-temp-buffer
          (insert comment)
          (goto-char (point-min))
          (flush-lines (concat "^[ \t]*/\\*" marker-re "[-*]+\\*/[ \t]*$"))
          (goto-char (point-min))
          (while (re-search-forward "^[ \t]*/\\* ?" nil t)
            (goto-char (match-beginning 0))
            (delete-region (match-beginning 0) (match-end 0)))
          (goto-char (point-min))
          (while (re-search-forward "[ \t]*\\*/[ \t]*$" nil t)
            (goto-char (match-beginning 0))
            (delete-region (match-beginning 0) (match-end 0)))
          (goto-char (point-min)) (delete-trailing-whitespace)
          (goto-char (point-min)) (flush-lines "^$")
          (set-fill-column (- 80   ; width of the text
                              6    ; width of "/*  */"
                              leader-width))
          (goto-char (point-min)) (fill-paragraph)
          (goto-char (point-min))
          (while (not (eobp))
            (insert (make-string leader-width ? ) "/* ")
            (goto-char (line-end-position))
            (insert (make-string (- 80 3 (current-column)) ? ) " */")
            (forward-line))
          (goto-char (point-min))
          (insert (make-string leader-width ? )
                  "/*" (make-string (- 80 4 leader-width) marker) "*/\n")
          (goto-char (point-max))
          (insert (make-string leader-width ? )
                  "/*" (make-string (- 80 4 leader-width) marker) "*/\n")
          (setq comment (buffer-string)))
        (goto-char begin)
        (delete-region begin end)
        (insert comment)))
    (goto-char here)))

(defun keep-mine ()
  (interactive)
  (beginning-of-line)
  (assert (or (looking-at "<<<<<<")
              (re-search-backward "^<<<<<<" nil t)
              (re-search-forward "^<<<<<<" nil t)))
  (goto-char (match-beginning 0))
  (let ((beg (point)))
    (forward-line)
    (delete-region beg (point))
    ;; (re-search-forward "^=======")
    (re-search-forward "^>>>>>>>")
    (setq beg (match-beginning 0))
    ;; (re-search-forward "^>>>>>>>")
    (re-search-forward "^=======")
    (forward-line)
    (delete-region beg (point))))

(defun keep-theirs ()
  (interactive)
  (beginning-of-line)
  (assert (or (looking-at "<<<<<<")
              (re-search-backward "^<<<<<<" nil t)
              (re-search-forward "^<<<<<<" nil t)))
  (goto-char (match-beginning 0))
  (let ((beg (point)))
    ;; (re-search-forward "^=======")
    (re-search-forward "^>>>>>>>")
    (forward-line)
    (delete-region beg (point))
    ;; (re-search-forward "^>>>>>>>")
    (re-search-forward "^#######")
    (beginning-of-line)
    (setq beg (point))
    (re-search-forward "^=======")
    (beginning-of-line)
    (forward-line)
    (delete-region beg (point))))

(defun keep-both ()
  (interactive)
  (beginning-of-line)
  (assert (or (looking-at "<<<<<<")
              (re-search-backward "^<<<<<<" nil t)
              (re-search-forward "^<<<<<<" nil t)))
  (beginning-of-line)
  (let ((beg (point)))
    (forward-line)
    (delete-region beg (point))
    (re-search-forward "^>>>>>>>")
    (beginning-of-line)
    (setq beg (point))
    (forward-line)
    (delete-region beg (point))
    (re-search-forward "^#######")
    (beginning-of-line)
    (setq beg (point))
    (re-search-forward "^=======")
    (beginning-of-line)
    (forward-line)
    (delete-region beg (point))))

(eval-after-load "cc-mode"
  '(progn
     (setq c-syntactic-indentation nil)

     (define-key c-mode-base-map "#" 'self-insert-command)
     (define-key c-mode-base-map "{" 'self-insert-command)
     (define-key c-mode-base-map "}" 'self-insert-command)
     (define-key c-mode-base-map "/" 'self-insert-command)
     (define-key c-mode-base-map "*" 'self-insert-command)
     (define-key c-mode-base-map ";" 'self-insert-command)
     (define-key c-mode-base-map "," 'self-insert-command)
     (define-key c-mode-base-map ":" 'self-insert-command)
     (define-key c-mode-base-map "(" 'self-insert-command)
     (define-key c-mode-base-map ")" 'self-insert-command)
     (define-key c++-mode-map "<"    'self-insert-command)
     (define-key c++-mode-map ">"    'self-insert-command)

     (define-key c-mode-base-map [(meta ?p)] 'keep-mine)
     (define-key c-mode-base-map [(meta ?n)] 'keep-theirs)
     (define-key c-mode-base-map [(alt ?b)] 'keep-both)

     (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)))

(eval-after-load "cc-styles"
  '(progn
     (add-to-list
      'c-style-alist
      '("edg"
        (indent-tabs-mode . nil)
        (c-basic-offset . 3)
        (c-comment-only-line-offset . (0 . 0))
        (c-hanging-braces-alist
         . ((substatement-open before after)
            (arglist-cont-nonempty)))
        (c-offsets-alist
         . ((statement-block-intro . +)
            (knr-argdecl-intro . 5)
            (substatement-open . 0)
            (substatement-label . 0)
            (label . 0)
            (case-label . +)
            (statement-case-open . 0)
            (statement-cont . +)
            (arglist-intro . c-lineup-arglist-intro-after-paren)
            (arglist-close . c-lineup-arglist)
            (inline-open . 0)
            (brace-list-open . 0)
            (topmost-intro-cont
             . (first c-lineup-topmost-intro-cont
                      c-lineup-gnu-DEFUN-intro-cont))))
        (c-special-indent-hook . c-gnu-impose-minimum)
        (c-block-comment-prefix . "")))

     (add-to-list
      'c-style-alist
      '("ledger"
        (indent-tabs-mode . nil)
        (c-basic-offset . 2)
        (c-comment-only-line-offset . (0 . 0))
        (c-hanging-braces-alist
         . ((substatement-open before after)
            (arglist-cont-nonempty)))
        (c-offsets-alist
         . ((statement-block-intro . +)
            (knr-argdecl-intro . 5)
            (substatement-open . 0)
            (substatement-label . 0)
            (label . 0)
            (case-label . 0)
            (statement-case-open . 0)
            (statement-cont . +)
            (arglist-intro . c-lineup-arglist-intro-after-paren)
            (arglist-close . c-lineup-arglist)
            (inline-open . 0)
            (brace-list-open . 0)
            (topmost-intro-cont
             . (first c-lineup-topmost-intro-cont
                      c-lineup-gnu-DEFUN-intro-cont))))
        (c-special-indent-hook . c-gnu-impose-minimum)
        (c-block-comment-prefix . "")))))

;;;   - ulp

(defun ulp ()
  (interactive)
  (find-file "~/src/ansi/ulp.c")
  (find-file-noselect "~/Contracts/TI/test/ulp_suite/invoke.sh")
  (find-file-noselect "~/Contracts/TI/test/ulp_suite")
  ;;(visit-tags-table "~/src/ansi/TAGS")
  (magit-status "~/src/ansi")
  (gdb "gdb --annotate=3 ~/Contracts/TI/bin/acpia470"))

;;;   - haskell-mode

(add-to-list 'auto-mode-alist '("\\.l?hs$" . haskell-mode))

(eval-when-compile
  (defvar haskell-check-command)
  (defvar haskell-mode-map))

(defun my-haskell-mode-hook ()
  (setq haskell-saved-check-command haskell-check-command)

  (define-key haskell-mode-map [(control ?c) ?w]
    'flymake-display-err-menu-for-current-line)
  (define-key haskell-mode-map [(control ?c) ?*]
    'flymake-start-syntax-check)
  (define-key haskell-mode-map [(meta ?n)] 'flymake-goto-next-error)
  (define-key haskell-mode-map [(meta ?p)] 'flymake-goto-prev-error))

(eval-after-load "haskell-site-file"
  '(progn
     (require 'inf-haskell)
     (require 'hs-lint)))

;;;   - ansicl

(info-lookmore-elisp-cl)

(mapc (lambda (mode)
        (info-lookup-add-help
         :mode mode
         :regexp "[^][()'\" \t\n]+"
         :ignore-case t
         :doc-spec '(("(ansicl)Symbol Index" nil nil nil))))
      '(lisp-mode slime-mode slime-repl-mode inferior-slime-mode))

(defadvice Info-exit (after remove-info-window activate)
  "When info mode is quit, remove the window."
  (if (> (length (window-list)) 1)
      (delete-window)))

;;;   - eldoc

(eval-after-load "eldoc"
  '(diminish 'eldoc-mode))

;;;   - elint

(defun elint-current-buffer ()
  (interactive)
  (elint-initialize)
  (elint-current-buffer))

(eval-after-load "elint"
  '(progn
     (add-to-list 'elint-standard-variables 'current-prefix-arg)
     (add-to-list 'elint-standard-variables 'command-line-args-left)
     (add-to-list 'elint-standard-variables 'buffer-file-coding-system)
     (add-to-list 'elint-standard-variables 'emacs-major-version)
     (add-to-list 'elint-standard-variables 'window-system)))

;;;   - paredit

(eval-after-load "paredit"
  '(diminish 'paredit-mode))

;;;   - redhank

(eval-after-load "redshank"
  '(diminish 'redshank-mode))

;;;   - lisp

(defface esk-paren-face
  '((((class color) (background dark))
     (:foreground "grey50"))
    (((class color) (background light))
     (:foreground "grey55")))
  "Face used to dim parentheses."
  :group 'starter-kit-faces)

(mapc (lambda (major-mode)
        (font-lock-add-keywords
         major-mode
         `(("(\\(lambda\\)\\>"
            (0 (ignore
                (compose-region (match-beginning 1)
                                (match-end 1) ?λ))))
           ("(\\|)" . 'esk-paren-face))))
      '(emacs-lisp-mode
        inferior-emacs-lisp-mode
        lisp-mode
        inferior-lisp-mode
        slime-repl-mode))

;;;   - lisp-mode-hook

(defun my-elisp-indent-or-complete (&optional arg)
  (interactive "p")
  (call-interactively 'lisp-indent-line)
  (unless (or (looking-back "^\\s-*")
              (bolp)
              (not (looking-back "[-A-Za-z0-9_*+/=<>!?]+")))
    (call-interactively 'lisp-complete-symbol)))

(defun my-lisp-indent-or-complete (&optional arg)
  (interactive "p")
  (if (or (looking-back "^\\s-*") (bolp))
      (call-interactively 'lisp-indent-line)
    (call-interactively 'slime-indent-and-complete-symbol)))

(defun my-lisp-mode-hook (&optional emacs-lisp-p)
  (let (mode-map)
    (if emacs-lisp-p
        (progn
          (require 'edebug)

          (setq mode-map emacs-lisp-mode-map)

          (define-key mode-map [(control ?c) ?I]
            (lambda ()
              (interactive)
              (anything
               :prompt "Info about: "
               :candidate-number-limit 5
               :sources
               '(anything-c-source-apropos-emacs-commands
                 anything-c-source-apropos-emacs-functions
                 anything-c-source-apropos-emacs-variables
                 anything-c-source-apropos-emacs-faces
                 anything-c-source-info-emacs
                 anything-c-source-info-elisp
                 anything-c-source-info-gnus
                 anything-c-source-info-org
                 anything-c-source-info-cl
                 anything-c-source-emacs-source-defun))))

          (define-key mode-map [(meta return)] 'outline-insert-heading)
          (define-key mode-map [tab] 'my-elisp-indent-or-complete)
          (define-key mode-map [tab] 'yas/expand))

      (turn-on-cldoc-mode)

      (setq mode-map lisp-mode-map)

      (define-key mode-map [tab] 'my-lisp-indent-or-complete)
      (define-key mode-map [(meta ?q)] 'slime-reindent-defun)
      (define-key mode-map [(meta ?l)] 'slime-selector))

    (auto-fill-mode 1)
    (paredit-mode 1)
    (redshank-mode 1)

    (column-marker-1 79)

    (define-key mode-map [(control ?h) ?F] 'info-lookup-symbol)))

(mapc (lambda (hook)
        (add-hook hook 'my-lisp-mode-hook))
      '(lisp-mode-hook inferior-lisp-mode-hook slime-repl-mode-hook))

(add-hook 'emacs-lisp-mode-hook (function (lambda () (my-lisp-mode-hook t))))

;;;   - python-mode

(add-to-list 'auto-mode-alist '("\\.py$" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))

(eval-when-compile
  (defvar py-mode-map))

(defun my-python-mode-hook ()
  (setq indicate-empty-lines t)
  (set (make-local-variable 'parens-require-spaces) nil)
  (setq indent-tabs-mode nil)

  (define-key py-mode-map [(control return)] 'other-window)
  (define-key py-mode-map [(control ?c) (control ?z)] 'python-shell))

(add-hook 'python-mode-hook 'my-python-mode-hook)

;;;   - nxml-mode

(defalias 'xml-mode 'nxml-mode)

(eval-when-compile
  (defvar nxml-mode-map))

(defun my-nxml-mode-hook ()
  (define-key nxml-mode-map [return] 'newline-and-indent)
  (define-key nxml-mode-map [(control return)] 'other-window))

(add-hook 'nxml-mode-hook 'my-nxml-mode-hook)

;;;   - zencoding

(setq zencoding-mode-keymap (make-sparse-keymap))

(define-key zencoding-mode-keymap (kbd "C-c C-c") 'zencoding-expand-line)

(add-hook 'nxml-mode-hook 'zencoding-mode)
(add-hook 'html-mode-hook 'zencoding-mode)

(eval-when-compile
  (defvar html-mode-map))

(add-hook 'html-mode-hook
          #'(lambda ()
              (interactive)
              (define-key html-mode-map [return] 'newline-and-indent)))

;;; * Keybindings

;;;   - global

(define-key global-map [(control meta backspace)] 'backward-kill-sexp)
(define-key global-map [(control meta delete)]    'backward-kill-sexp)

(define-key global-map [(meta ?/)] 'dabbrev-expand)
(define-key global-map [(meta ??)] 'anything-dabbrev-expand)

(define-key global-map [(control ?.)] 'ace-jump-mode)

(defun tidy-xml-buffer ()
  (interactive)
  (save-excursion
    (call-process-region (point-min) (point-max) "tidy" t t nil
                         "-xml" "-i" "-wrap" "0" "-omit" "-q")))

(define-key global-map [(control shift ?h)] 'tidy-xml-buffer)

(defun isearch-backward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-backward))

(define-key global-map [(control meta ?r)] 'isearch-backward-other-window)

(defun isearch-forward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-forward))

(define-key global-map [(control meta ?s)] 'isearch-forward-other-window)

(defun collapse-or-expand ()
  (interactive)
  (if (> (length (window-list)) 1)
      (delete-other-windows)
    (bury-buffer)))

(define-key global-map [(control ?z)] 'collapse-or-expand)

(defun delete-indentation-forward ()
  (interactive)
  (delete-indentation t))

(define-key global-map [(meta ?n)] 'ignore)
(define-key global-map [(meta ?p)] 'ignore)

(define-key global-map [(meta ?j)] 'delete-indentation-forward)
(define-key global-map [(meta ?J)] 'delete-indentation)

(defvar lisp-find-map)
(define-prefix-command 'lisp-find-map)
(define-key global-map [(control ?h) ?e] 'lisp-find-map)
(define-key lisp-find-map [?a] 'apropos)
(define-key lisp-find-map [?e] 'view-echo-area-messages)
(define-key lisp-find-map [?f] 'find-function)
(define-key lisp-find-map [?i] 'info-apropos)
(define-key lisp-find-map [?v] 'find-variable)
(define-key lisp-find-map [?k] 'find-function-on-key)

(defun gnus-level-1 ()
  (interactive)
  (gnus 1))

(define-key global-map [(meta ?B)] 'bbdb)
(define-key global-map [(meta ?C)] 'jump-to-org-agenda)
(define-key global-map [(meta ?G)] 'gnus-level-1)
(define-key global-map [(meta ?m)] 'org-smart-capture)
(define-key global-map [(meta ?M)] 'org-inline-note)
(define-key global-map [(meta ?N)] 'winner-redo)
(define-key global-map [(meta ?P)] 'winner-undo)
(define-key global-map [(meta ?T)] 'tags-search)

(define-key global-map [(meta ?:)] 'pp-eval-expression)
(define-key global-map [(meta ?\')] 'insert-pair)
(define-key global-map [(meta ?\")] 'insert-pair)

(defun align-code (beg end &optional arg)
  (interactive "rP")
  (if (null arg)
      (align beg end)
    (let ((end-mark (copy-marker end)))
      (indent-region beg end-mark nil)
      (align beg end-mark))))

(define-key global-map [(meta ?\[)] 'align-code)
(define-key global-map [(meta ?`)]  'other-frame)
(define-key global-map [(alt ?`)]   'other-frame)

(defun mark-line (&optional arg)
  (interactive "p")
  (beginning-of-line)
  (let ((here (point)))
    (dotimes (i arg)
      (end-of-line))
    (set-mark (point))
    (goto-char here)))

(defun mark-sentence (&optional arg)
  (interactive "P")
  (backward-sentence)
  (mark-end-of-sentence arg))

(define-key global-map [(meta shift ?w)] 'mark-word)
(define-key global-map [(meta shift ?l)] 'mark-line)
(define-key global-map [(meta shift ?s)] 'mark-sentence)
(define-key global-map [(meta shift ?x)] 'mark-sexp)
(define-key global-map [(meta shift ?h)] 'mark-paragraph)
(define-key global-map [(meta shift ?d)] 'mark-defun)

(define-key global-map [(control return)] 'other-window)

(define-key global-map [f9] 'gud-cont)
(define-key global-map [f10] 'gud-next)
(define-key global-map [f11] 'gud-step)
(define-key global-map [(shift f11)] 'gud-finish)

(define-key global-map [(alt ?v)] 'scroll-down)
(define-key global-map [(meta ?v)] 'yank)

(define-key global-map [(alt tab)]
  #'(lambda ()
      (interactive)
      (call-interactively (key-binding (kbd "M-TAB")))))

;;;   - ctl-x

(eval-when-compile
  (require 'bookmark))

(defun ido-bookmark-jump (bookmark &optional display-func)
  (interactive
   (list
    (ido-completing-read "Jump to bookmark: "
                         (mapcar #'car bookmark-alist)
                         nil 0 nil 'bookmark-history)))
  (unless bookmark
    (error "No bookmark specified"))
  (bookmark-maybe-historicize-string bookmark)
  (bookmark--jump-via bookmark (or display-func 'switch-to-buffer)))

(define-key ctl-x-map [?r ?b] 'ido-bookmark-jump)

(define-key ctl-x-map [?d] 'delete-whitespace-rectangle)
(define-key ctl-x-map [?g] 'magit-status)
(define-key ctl-x-map [?m] 'compose-mail)
(define-key ctl-x-map [?t] 'toggle-truncate-lines)

(defun unfill-paragraph (arg)
  (interactive "*p")
  (let (beg end)
    (forward-paragraph arg)
    (setq end (copy-marker (- (point) 2)))
    (backward-paragraph arg)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (when (> (count-lines beg end) 1)
      (while (< (point) end)
        (goto-char (line-end-position))
        (let ((sent-end (memq (char-before) '(?. ?\; ?! ??))))
          (delete-indentation 1)
          (if sent-end
              (insert ? )))
        (end-of-line))
      (save-excursion
        (goto-char beg)
        (while (re-search-forward "[^.;!?:]\\([ \t][ \t]+\\)" end t)
          (replace-match " " nil nil nil 1))))))

(defun unfill-region (beg end)
  (interactive "r")
  (setq end (copy-marker end))
  (save-excursion
    (goto-char beg)
    (while (< (point) end)
      (unfill-paragraph 1)
      (forward-paragraph))))

(defun refill-paragraph (arg)
  (interactive "*P")
  (let ((fun (if (memq major-mode '(c-mode c++-mode))
                 'c-fill-paragraph
               (or fill-paragraph-function
                   'fill-paragraph)))
        (width (if (numberp arg) arg))
        prefix beg end)
    (forward-paragraph 1)
    (setq end (copy-marker (- (point) 2)))
    (forward-line -1)
    (let ((b (point)))
      (skip-chars-forward "^A-Za-z0-9`'\"(")
      (setq prefix (buffer-substring-no-properties b (point))))
    (backward-paragraph 1)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (delete-horizontal-space)
    (while (< (point) end)
      (delete-indentation 1)
      (end-of-line))
    (let ((fill-column (or width fill-column))
          (fill-prefix prefix))
      (if prefix
          (setq fill-column
                (- fill-column (* 2 (length prefix)))))
      (funcall fun nil)
      (goto-char beg)
      (insert prefix)
      (funcall fun nil))
    (goto-char (+ end 2))))

(define-key ctl-x-map [(meta ?q)] 'refill-paragraph)
(define-key mode-specific-map [(meta ?q)] 'unfill-paragraph)

(define-key ctl-x-map [(control ?b)] 'ibuffer)

(defun duplicate-line ()
  "Duplicate the line containing point."
  (interactive)
  (save-excursion
    (let (line-text)
      (goto-char (line-beginning-position))
      (let ((beg (point)))
        (goto-char (line-end-position))
        (setq line-text (buffer-substring beg (point))))
      (if (eobp)
          (insert ?\n)
        (forward-line))
      (open-line 1)
      (insert line-text))))

(define-key ctl-x-map [(control ?d)] 'duplicate-line)
(define-key ctl-x-map [(control ?e)] 'pp-eval-last-sexp)
(define-key ctl-x-map [(control ?z)] 'eshell-toggle)
(define-key ctl-x-map [(meta ?z)] 'shell-toggle)

;;;   - mode-specific

(define-key mode-specific-map [tab] 'ff-find-other-file)

(define-key mode-specific-map [space] 'just-one-space)
(define-key mode-specific-map [? ] 'just-one-space)

;; inspired by Erik Naggum's `recursive-edit-with-single-window'
(defmacro recursive-edit-preserving-window-config (body)
  "*Return a command that enters a recursive edit after executing BODY.
 Upon exiting the recursive edit (with\\[exit-recursive-edit] (exit)
 or \\[abort-recursive-edit] (abort)), restore window configuration
 in current frame."
  `(lambda ()
     "See the documentation for `recursive-edit-preserving-window-config'."
     (interactive)
     (save-window-excursion
       ,body
       (recursive-edit))))

(define-key mode-specific-map [?0]
  (recursive-edit-preserving-window-config (delete-window)))
(define-key mode-specific-map [?1]
  (recursive-edit-preserving-window-config
   (if (one-window-p 'ignore-minibuffer)
       (error "Current window is the only window in its frame")
     (delete-other-windows))))

(define-key mode-specific-map [?a] 'org-agenda)

(defun find-grep-in-project (command-args)
  (interactive
   (progn
     (list (read-shell-command
            "Run find (like this): "
            '("git ls-files -z | xargs -P4 -0 egrep -nH -e " . 45)
            'grep-find-history))))
  (when command-args
    (let ((null-device nil))            ; see grep
      (grep command-args))))

(define-prefix-command 'my-grep-map)
(define-key mode-specific-map [?b] 'my-grep-map)
(define-key mode-specific-map [?b ?a] 'anything-do-grep)
(define-key mode-specific-map [?b ?b] 'anything-occur)
(define-key mode-specific-map [?b ?d] 'find-grep-dired)
(define-key mode-specific-map [?b ?f] 'find-grep)
(define-key mode-specific-map [?b ?F] 'anything-for-files)
(define-key mode-specific-map [?b ?g] 'grep)
(define-key mode-specific-map [?b ?n] 'find-name-dired)
(define-key mode-specific-map [?b ?o] 'occur)
(define-key mode-specific-map [?b ?p] 'find-grep-in-project)
(define-key mode-specific-map [?b ?r] 'rgrep)

(define-key global-map [(meta ?s) ?a] 'anything-do-grep)
(define-key global-map [(meta ?s) ?b] 'anything-occur)
(define-key global-map [(meta ?s) ?d] 'find-grep-dired)
(define-key global-map [(meta ?s) ?f] 'find-grep)
(define-key global-map [(meta ?s) ?F] 'anything-for-files)
(define-key global-map [(meta ?s) ?g] 'grep)
(define-key global-map [(meta ?s) ?n] 'find-name-dired)
(define-key global-map [(meta ?s) ?p] 'find-grep-in-project)
(define-key global-map [(meta ?s) ?r] 'rgrep)

(define-key mode-specific-map [?c] 'compile)
(define-key mode-specific-map [?C] 'indirect-region)

(defun delete-current-line (&optional arg)
  (interactive "p")
  (let ((here (point)))
    (beginning-of-line)
    (kill-line arg)
    (goto-char here)))

(define-key mode-specific-map [?d] 'delete-current-line)

(defun do-eval-buffer ()
  (interactive)
  (call-interactively 'eval-buffer)
  (message "Buffer has been evaluated"))

(defun scratch ()
  (interactive)
  (switch-to-buffer-other-window (get-buffer-create "*scratch*"))
  ;;(lisp-interaction-mode)
  (text-mode)
  (goto-char (point-min))
  (when (looking-at ";")
    (forward-line 4)
    (delete-region (point-min) (point)))
  (goto-char (point-max)))

(defun find-which (name)
  (interactive "sCommand name: ")
  (find-file-other-window
   (substring (shell-command-to-string (format "which %s" name)) 0 -1)))

(define-key global-map [(control ?h) ?e ?a] 'anything-apropos)
(define-key mode-specific-map [?e ?a] 'anything-apropos)
(define-key mode-specific-map [?e ?b] 'do-eval-buffer)
(define-key mode-specific-map [?e ?c] 'cancel-debug-on-entry)
(define-key mode-specific-map [?e ?d] 'debug-on-entry)
(define-key mode-specific-map [?e ?f] 'emacs-lisp-byte-compile-and-load)
(define-key mode-specific-map [?e ?r] 'eval-region)
(define-key mode-specific-map [?e ?l] 'find-library)
(define-key mode-specific-map [?e ?s] 'scratch)
(define-key mode-specific-map [?e ?v] 'edit-variable)
(define-key mode-specific-map [?e ?w] 'find-which)
(define-key mode-specific-map [?e ?e] 'toggle-debug-on-error)
(define-key mode-specific-map [?e ?E] 'elint-current-buffer)
(define-key mode-specific-map [?e ?z] 'byte-recompile-directory)

(define-key mode-specific-map [?f] 'flush-lines)
(define-key mode-specific-map [?g] 'goto-line)

(define-key mode-specific-map [?i ?b] 'flyspell-buffer)
(define-key mode-specific-map [?i ?c] 'ispell-comments-and-strings)
(define-key mode-specific-map [?i ?d] 'ispell-change-dictionary)
(define-key mode-specific-map [?i ?f] 'flyspell-mode)
(define-key mode-specific-map [?i ?k] 'ispell-kill-ispell)
(define-key mode-specific-map [?i ?m] 'ispell-message)
(define-key mode-specific-map [?i ?r] 'ispell-region)

(define-key mode-specific-map [?j] 'dired-jump)
(define-key mode-specific-map [?J] 'dired-jump-other-window)

(defun dired-double-jump (first-dir second-dir)
  (interactive
   (list (ido-read-directory-name "First directory: "
                                  (expand-file-name "~/") "~/dl")
         (ido-read-directory-name "Second directory: "
                                  (expand-file-name "~/") "~/dl")))
  (dired first-dir)
  (dired-other-window second-dir))

(define-key mode-specific-map [?J] 'dired-double-jump)

(define-key mode-specific-map [(control ?j)] 'dired-jump)
(define-key mode-specific-map [?k] 'keep-lines)

(defun my-ledger-start-entry (&optional arg)
  (interactive "p")
  (find-file-other-window "~/Documents/Accounts/ledger.dat")
  (goto-char (point-max))
  (skip-syntax-backward " ")
  (if (looking-at "\n\n")
      (goto-char (point-max))
    (delete-region (point) (point-max))
    (insert ?\n)
    (insert ?\n))
  (insert (format-time-string "%Y/%m/%d ")))

(define-key mode-specific-map [?L] 'my-ledger-start-entry)

(defun emacs-min ()
  (interactive)
  (set-frame-parameter (selected-frame) 'fullscreen nil)
  (set-frame-parameter (selected-frame) 'top 26)
  (set-frame-parameter (selected-frame) 'left
                       (- (x-display-pixel-width) 937))
  (set-frame-parameter (selected-frame) 'width 100)
  (set-frame-parameter (selected-frame) 'height 100))

(defun emacs-max ()
  (interactive)
  (if t
      (set-frame-parameter (selected-frame) 'fullscreen 'fullboth)
    (set-frame-parameter (selected-frame) 'top 26)
    (set-frame-parameter (selected-frame) 'left 2)
    (set-frame-parameter (selected-frame) 'width
                         (floor (/ (float (x-display-pixel-width)) 9.15)))
    (set-frame-parameter (selected-frame) 'height 100)))

(defun emacs-toggle-size ()
  (interactive)
  (if (> (cdr (assq 'width (frame-parameters))) 100)
      (emacs-min)
    (emacs-max)))

(define-key mode-specific-map [?m] 'emacs-toggle-size)

(defcustom user-initials nil
  "*Initials of this user."
  :set
  #'(lambda (symbol value)
      (if (fboundp 'font-lock-add-keywords)
          (mapc
           #'(lambda (mode)
               (font-lock-add-keywords
                mode (list (list (concat "\\<\\(" value " [^:\n]+\\):")
                                 1 font-lock-warning-face t))))
           '(c-mode c++-mode emacs-lisp-mode lisp-mode
                    python-mode perl-mode java-mode groovy-mode)))
      (set symbol value))
  :type 'string
  :group 'mail)

(defun insert-user-timestamp ()
  "Insert a quick timestamp using the value of `user-initials'."
  (interactive)
  (insert (format "%s (%s): " user-initials
                  (format-time-string "%Y-%m-%d" (current-time)))))

(define-key mode-specific-map [?n] 'insert-user-timestamp)
(define-key mode-specific-map [?o] 'customize-option)
(define-key mode-specific-map [?O] 'customize-group)

(defvar printf-index 0)

(defun insert-counting-printf (arg)
  (interactive "P")
  (if arg
      (setq printf-index 0))
  (insert (format "printf(\"step %d..\\n\");\n"
                  (setq printf-index (1+ printf-index))))
  (forward-line -1)
  (indent-according-to-mode)
  (forward-line))

(define-key mode-specific-map [?p] 'insert-counting-printf)

(define-key mode-specific-map [?q] 'fill-region)
(define-key mode-specific-map [?r] 'replace-regexp)
(define-key mode-specific-map [?s] 'replace-string)

(define-key mode-specific-map [?S] 'org-store-link)
(define-key mode-specific-map [?l] 'org-insert-link)

;;(define-key mode-specific-map [?t ?g] 'gtags-find-with-grep)
;;(define-key mode-specific-map [?t ?r] 'gtags-find-rtag)
;;(define-key mode-specific-map [?t ?s] 'gtags-find-symbol)
;;(define-key mode-specific-map [?t ?t] 'gtags-find-tag)
;;(define-key mode-specific-map [?t ?v] 'gtags-visit-rootdir)
(define-key mode-specific-map [?t ?%] 'tags>-query-replace)
(define-key mode-specific-map [?t ?a] 'tags-apropos)
(define-key mode-specific-map [?t ?e] 'tags-search)
(define-key mode-specific-map [?t ?v] 'visit-tags-table)

(define-key mode-specific-map [?u] 'rename-uniquely)
(define-key mode-specific-map [?v] 'ffap)

(defun view-clipboard ()
  (interactive)
  (delete-other-windows)
  (switch-to-buffer "*Clipboard*")
  (let ((inhibit-read-only t))
    (erase-buffer)
    (clipboard-yank)
    (goto-char (point-min))
    (html-mode)
    (view-mode)))

(define-key mode-specific-map [?V] 'view-clipboard)
(define-key mode-specific-map [?z] 'clean-buffer-list)

(define-key mode-specific-map [?, ?c] 'howm-create)
(define-key mode-specific-map [?, ?g] 'howm-list-grep)

(let ((map (make-sparse-keymap)))
  (define-key map " " 'outline-mark-subtree)
  (define-key map "n" 'outline-next-visible-heading)
  (define-key map "p" 'outline-previous-visible-heading)
  (define-key map "i" 'show-children)
  (define-key map "s" 'show-subtree)
  (define-key map "d" 'hide-subtree)
  (define-key map "u" 'outline-up-heading)
  (define-key map "f" 'outline-forward-same-level)
  (define-key map "b" 'outline-backward-same-level)
  (define-key map "t" 'hide-body)
  (define-key map "a" 'show-all)
  (define-key map "c" 'hide-entry)
  (define-key map "e" 'show-entry)
  (define-key map "l" 'hide-leaves)
  (define-key map "k" 'show-branches)
  (define-key map "q" 'hide-sublevels)
  (define-key map "o" 'hide-other)
  (define-key map "^" 'outline-move-subtree-up)
  (define-key map "v" 'outline-move-subtree-down)
  (define-key map [?<] 'outline-promote)
  (define-key map [?>] 'outline-demote)
  (define-key map "\C-m" 'outline-insert-heading)

  (define-key mode-specific-map [?.] map))

(define-key mode-specific-map [?\[] 'align-regexp)
(define-key mode-specific-map [?=]  'count-matches)
(define-key mode-specific-map [?\;] 'comment-or-uncomment-region)

;;;   - breadcrumb

(define-key global-map [(alt ?m)] 'bc-set)
(define-key global-map [(alt ?p)] 'bc-previous)
(define-key global-map [(alt ?n)] 'bc-next)
(define-key global-map [(alt ?u)] 'bc-local-previous)
(define-key global-map [(alt ?d)] 'bc-local-next)
(define-key global-map [(alt ?g)] 'bc-goto-current)
(define-key global-map [(alt ?l)] 'bc-list)

;;;   - footnote

(eval-after-load "footnote"
  '(define-key footnote-mode-map "#" 'redo-footnotes))

;;;   - isearch-mode

(eval-after-load "isearch"
  '(progn
     (define-key isearch-mode-map [(control ?c)] 'isearch-toggle-case-fold)
     (define-key isearch-mode-map [(control ?t)] 'isearch-toggle-regexp)
     (define-key isearch-mode-map [(control ?^)] 'isearch-edit-string)
     (define-key isearch-mode-map [(control ?i)] 'isearch-complete)))

;;;   - mail-mode

(eval-after-load "sendmail"
  '(progn
     (define-key mail-mode-map [tab] 'mail-complete)
     (define-key mail-mode-map [(control ?i)] 'mail-complete)))

;;; * Org-mode

(require 'org)
(require 'org-agenda)

;;(require 'org-crypt)
(require 'org-devonthink)
(require 'org-magit)
(require 'org-x)
(require 'ox-org)
(require 'ox-redmine)
(require 'ob-R)
(require 'ob-python)
(require 'ob-emacs-lisp)
;;(require 'ob-haskell)
(require 'ob-sh)

;;(load "org-log" t)

(defun jump-to-org-agenda ()
  (interactive)
  (let ((buf (get-buffer "*Org Agenda*"))
        wind)
    (if buf
        (if (setq wind (get-buffer-window buf))
            (when (called-interactively-p 'any)
              (select-window wind)
              (org-fit-window-to-buffer))
          (if (called-interactively-p 'any)
              (progn
                (select-window (display-buffer buf t t))
                (org-fit-window-to-buffer))
            (with-selected-window (display-buffer buf)
              (org-fit-window-to-buffer))))
      (call-interactively 'org-agenda-list))))

(run-with-idle-timer 300 t 'jump-to-org-agenda)

(defun org-export-tasks ()
  (interactive)
  (let ((index 1))
    (org-map-entries
     #'(lambda ()
         (outline-mark-subtree)
         (org-export-as-html 3)
         (write-file (format "%d.html" index))
         (kill-buffer (current-buffer))
         (setq index (1+ index)))
     "LEVEL=2")))

(defun org-agenda-add-overlays (&optional line)
  "Add overlays found in OVERLAY properties to agenda items.
Note that habitual items are excluded, as they already
extensively use text properties to draw the habits graph.

For example, for work tasks I like to use a subtle, yellow
background color; for tasks involving other people, green; and
for tasks concerning only myself, blue.  This way I know at a
glance how different responsibilities are divided for any given
day.

To achieve this, I have the following in my todo file:

  * Work
    :PROPERTIES:
    :CATEGORY: Work
    :OVERLAY:  (face (:background \"#fdfdeb\"))
    :END:
  ** TODO Task
  * Family
    :PROPERTIES:
    :CATEGORY: Personal
    :OVERLAY:  (face (:background \"#e8f9e8\"))
    :END:
  ** TODO Task
  * Personal
    :PROPERTIES:
    :CATEGORY: Personal
    :OVERLAY:  (face (:background \"#e8eff9\"))
    :END:
  ** TODO Task

The colors (which only work well for white backgrounds) are:

  Yellow: #fdfdeb
  Green:  #e8f9e8
  Blue:   #e8eff9

To use this function, add it to `org-agenda-finalize-hook':

  (add-hook 'org-finalize-agenda-hook 'org-agenda-add-overlays)"
  (let ((inhibit-read-only t) l c
        (buffer-invisibility-spec '(org-link)))
    (save-excursion
      (goto-char (if line (point-at-bol) (point-min)))
      (while (not (eobp))
        (let ((org-marker (get-text-property (point) 'org-marker)))
          (when (and org-marker
                     (null (overlays-at (point)))
                     (not (get-text-property (point) 'org-habit-p))
                     (string-match "\\(sched\\|dead\\|todo\\)"
                                   (get-text-property (point) 'type)))
            (let ((overlays (org-entry-get org-marker "OVERLAY" t)))
              (when overlays
                (goto-char (line-end-position))
                (let ((rest (- (window-width) (current-column))))
                  (if (> rest 0)
                      (insert (make-string rest ? ))))
                (let ((ol (make-overlay (line-beginning-position)
                                        (line-end-position)))
                      (proplist (read overlays)))
                  (while proplist
                    (overlay-put ol (car proplist) (cadr proplist))
                    (setq proplist (cddr proplist))))))))
        (forward-line)))))

(add-hook 'org-finalize-agenda-hook 'org-agenda-add-overlays)

(defun org-my-message-open (message-id)
  (gnus-goto-article
   (gnus-string-remove-all-properties (substring message-id 2))))

;;(defun org-my-message-open (message-id)
;;  (condition-case err
;;      (if (get-buffer "*Group*")
;;          (gnus-goto-article
;;           (gnus-string-remove-all-properties (substring message-id 2)))
;;        (org-mac-message-open message-id))
;;    (error
;;     (org-mac-message-open message-id))))

(add-to-list 'org-link-protocols (list "message" 'org-my-message-open nil))

(defun save-org-mode-files ()
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (eq major-mode 'org-mode)
        (if (and (buffer-modified-p) (buffer-file-name))
            (save-buffer))))))

(run-with-idle-timer 25 t 'save-org-mode-files)

(defun my-org-push-mobile ()
  (interactive)
  (with-current-buffer (find-file-noselect "~/Documents/Tasks/todo.txt")
    (org-mobile-push)))

(defun org-my-auto-exclude-function (tag)
  (and (cond
        ((string= tag "call")
         (let ((hour (nth 2 (decode-time))))
           (or (< hour 8) (> hour 21))))
        ((string= tag "errand")
         (let ((hour (nth 2 (decode-time))))
           (or (< hour 12) (> hour 17))))
        ((or (string= tag "home") (string= tag "nasim"))
         (with-temp-buffer
           (call-process "/sbin/ifconfig" nil t nil "en0" "inet")
           (call-process "/sbin/ifconfig" nil t nil "en1" "inet")
           (call-process "/sbin/ifconfig" nil t nil "bond0" "inet")
           (goto-char (point-min))
           (not (re-search-forward "inet 192\\.168\\.9\\." nil t))))
        ((string= tag "net")
         (/= 0 (call-process "/sbin/ping" nil nil nil
                             "-c1" "-q" "-t1" "mail.gnu.org")))
        ((string= tag "fun")
         org-clock-current-task))
       (concat "-" tag)))

(defun my-mobileorg-convert ()
  (interactive)
  (while (re-search-forward "^\\* " nil t)
    (goto-char (match-beginning 0))
    (insert ?*)
    (forward-char 2)
    (insert "TODO ")
    (goto-char (line-beginning-position))
    (forward-line)
    (re-search-forward "^\\[")
    (goto-char (match-beginning 0))
    (let ((uuid
           (save-excursion
             (re-search-forward "^\\*\\* Note ID: \\(.+\\)")
             (prog1
                 (match-string 1)
               (delete-region (match-beginning 0)
                              (match-end 0))))))
      (insert (format "   SCHEDULED: %s\n   :PROPERTIES:\n"
                      (format-time-string (org-time-stamp-format))))
      (insert (format "   :ID:       %s\n   :CREATED:  " uuid)))
    (forward-line)
    (insert "   :END:")))

(eval-when-compile
  (require 'org-mobile))

(defun my-org-convert-incoming-items ()
  (interactive)
  (with-current-buffer
      (find-file-noselect (expand-file-name org-mobile-capture-file
                                            org-mobile-directory))
    (goto-char (point-min))
    (my-mobileorg-convert)
    (let ((tasks (buffer-string)))
      (set-buffer-modified-p nil)
      (kill-buffer (current-buffer))
      (with-current-buffer (find-file-noselect "~/Documents/Tasks/todo.txt")
        (save-excursion
          (goto-char (point-min))
          (re-search-forward "^\\* Inbox$")
          (re-search-forward "^  :END:")
          (forward-line)
          (goto-char (line-beginning-position))
          (if (and tasks (> (length tasks) 0))
              (insert tasks ?\n)))))))

;;; Don't sync agendas.org to MobileOrg.  I do this because I only use
;;; MobileOrg for recording new tasks on the phone, and never for viewing
;;; tasks.  This allows MobileOrg to start up and sync extremely quickly.

(add-hook 'org-mobile-post-push-hook
          (function
           (lambda ()
             (shell-command "/bin/rm -f ~/Dropbox/MobileOrg/agendas.org")
             (shell-command
              (concat "perl -i -ne 'print unless /agendas\\.org/;'"
                      "~/Dropbox/MobileOrg/checksums.dat"))
             (shell-command
              (concat "perl -i -ne 'print unless /agendas\\.org/;'"
                      "~/Dropbox/MobileOrg/index.org")))))

(add-hook 'org-mobile-pre-pull-hook 'my-org-convert-incoming-items)

(defun org-my-state-after-clock-out (state)
  (if (string= state "STARTED")
      "TODO"
    state))

(defvar org-my-archive-expiry-days 1
  "The number of days after which a completed task should be auto-archived.
This can be 0 for immediate, or a floating point value.")

(defconst org-my-ts-regexp
  "[[<]\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [^]>\r\n]*?\\)[]>]"
  "Regular expression for fast inactive time stamp matching.")

(defun org-my-closing-time ()
  (let* ((state-regexp
          (concat "- State \"\\(?:" (regexp-opt org-done-keywords)
                  "\\)\"\\s-*\\[\\([^]\n]+\\)\\]"))
         (regexp (concat "\\(" state-regexp "\\|" org-my-ts-regexp "\\)"))
         (end (save-excursion
                (outline-next-heading)
                (point)))
         begin
         end-time)
    (goto-char (line-beginning-position))
    (while (re-search-forward regexp end t)
      (let ((moment (org-parse-time-string (match-string 1))))
        (if (or (not end-time)
                (time-less-p (apply #'encode-time end-time)
                             (apply #'encode-time moment)))
            (setq end-time moment))))
    (goto-char end)
    end-time))

(defun org-my-archive-done-tasks ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((done-regexp
           (concat "^\\*\\* \\(" (regexp-opt org-done-keywords) "\\) ")))
      (while (re-search-forward done-regexp nil t)
        (if (>= (time-to-number-of-days
                 (time-subtract (current-time)
                                (apply #'encode-time (org-my-closing-time))))
                org-my-archive-expiry-days)
            (org-archive-subtree))))
    (save-buffer)))

(defalias 'archive-done-tasks 'org-my-archive-done-tasks)

(defun org-get-inactive-time ()
  (float-time (org-time-string-to-time
               (or (org-entry-get (point) "TIMESTAMP")
                   (org-entry-get (point) "TIMESTAMP_IA")
                   (debug)))))

(defun org-get-completed-time ()
  (let ((begin (point)))
    (save-excursion
      (outline-next-heading)
      (and (re-search-backward "\\(- State \"\\(DONE\\|DEFERRED\\|CANCELED\\)\"\\s-+\\[\\(.+?\\)\\]\\|CLOSED: \\[\\(.+?\\)\\]\\)" begin t)
           (float-time (org-time-string-to-time (or (match-string 3)
                                                    (match-string 4))))))))

(defun org-my-sort-done-tasks ()
  (interactive)
  (goto-char (point-min))
  (org-sort-entries t ?F #'org-get-inactive-time #'<)
  (goto-char (point-min))
  (while (re-search-forward "


+" nil t)
    (delete-region (match-beginning 0) (match-end 0))
    (insert "
"))
  (let (after-save-hook)
    (save-buffer))
  (org-overview))

(defalias 'sort-done-tasks 'org-my-sort-done-tasks)

(defun org-archive-done-tasks ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\* \\(DONE\\|CANCELED\\) " nil t)
      (if (save-restriction
            (save-excursion
              (org-x-narrow-to-entry)
              (search-forward ":LOGBOOK:" nil t)))
          (forward-line)
        (org-archive-subtree)
        (goto-char (line-beginning-position))))))

(defun org-sort-all ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^\* " nil t)
      (goto-char (match-beginning 0))
      (condition-case err
          (progn
            (org-sort-entries t ?a)
            (org-sort-entries t ?p)
            (org-sort-entries t ?o)
            (forward-line))
        (error nil)))
    (goto-char (point-min))
    (while (re-search-forward "\* PROJECT " nil t)
      (goto-char (line-beginning-position))
      (ignore-errors
        (org-sort-entries t ?a)
        (org-sort-entries t ?p)
        (org-sort-entries t ?o))
      (forward-line))))

(defun org-cleanup ()
  (interactive)
  (org-archive-done-tasks)
  (org-sort-all)
  ;;(org-x-normalize-all-entries)
  )

(defun org-maybe-remember (&optional done)
  (interactive "P")
  (if (string= (buffer-name) "*Remember*")
      (call-interactively 'org-ctrl-c-ctrl-c)
    (if (null done)
        (call-interactively 'org-remember)
      (let ((org-capture-templates
             '((110 "* STARTED %?
  - State \"STARTED\"    %U
  SCHEDULED: %t
  :PROPERTIES:
  :ID:       %(shell-command-to-string \"uuidgen\")  :CREATED:  %U
  :END:" "~/Documents/Tasks/todo.txt" "Inbox"))))
        (org-remember))))
  (set-fill-column 72))

(defun org-inline-note ()
  (interactive)
  (switch-to-buffer-other-window "todo.txt")
  (goto-char (point-min))
  (re-search-forward "^\\* Inbox$")
  (re-search-forward "^  :END:")
  (forward-line)
  (goto-char (line-beginning-position))
  (insert "** NOTE ")
  (save-excursion
    (insert (format "
   :PROPERTIES:
   :ID:       %s   :VISIBILITY: folded
   :CREATED:  %s
   :END:" (shell-command-to-string "uuidgen")
   (format-time-string (org-time-stamp-format t t))))
    (insert ?\n))
  (save-excursion
    (forward-line)
    (org-cycle)))

;;(defun org-get-apple-message-link ()
;;  (let ((subject (do-applescript "tell application \"Mail\"
;;        set theMessages to selection
;;        subject of beginning of theMessages
;;end tell"))
;;        (message-id (do-applescript "tell application \"Mail\"
;;        set theMessages to selection
;;        message id of beginning of theMessages
;;end tell")))
;;    (org-make-link-string (concat "message://" message-id) subject)))
;;
;;(defun org-get-message-sender ()
;;  (do-applescript "tell application \"Mail\"
;;        set theMessages to selection
;;        sender of beginning of theMessages
;;end tell"))
;;
;;(defun org-insert-apple-message-link ()
;;  (interactive)
;;  (insert (org-get-apple-message-link)))

(defun org-get-message-link ()
  (assert (get-buffer "*Group*"))
  (let (message-id subject)
    (with-current-buffer gnus-original-article-buffer
      (setq message-id (substring (message-field-value "message-id") 1 -1)
            subject (message-field-value "subject")))
    (org-make-link-string (concat "message://" message-id) subject)))

(defun org-insert-message-link ()
  (interactive)
  (insert (org-get-message-link)))

(defun org-set-message-link ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "Message" (org-get-message-link)))

(defun org-get-message-sender ()
  (assert (get-buffer "*Group*"))
  (let (message-id subject)
    (with-current-buffer gnus-original-article-buffer
      (message-field-value "from"))))

(defun org-set-message-sender ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "Submitter" (org-get-message-sender)))

;;(defun org-get-safari-link ()
;;  (let ((subject (do-applescript "tell application \"Safari\"
;;        name of document of front window
;;end tell"))
;;        (url (do-applescript "tell application \"Safari\"
;;        URL of document of front window
;;end tell")))
;;    (org-make-link-string url subject)))

(defun org-get-chrome-link ()
  (let ((subject (do-applescript "tell application \"Google Chrome\"
        title of active tab of front window
end tell"))
        (url (do-applescript "tell application \"Google Chrome\"
        URL of active tab of front window
end tell")))
    (org-make-link-string url subject)))

(defun org-insert-url-link ()
  (interactive)
  (insert (org-get-chrome-link)))

(defun org-set-url-link ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "URL" (org-get-chrome-link)))

;;(defun org-get-file-link ()
;;  (let ((subject (do-applescript "tell application \"Finder\"
;;      set theItems to the selection
;;      name of beginning of theItems
;;end tell"))
;;        (path (do-applescript "tell application \"Finder\"
;;      set theItems to the selection
;;      POSIX path of (beginning of theItems as text)
;;end tell")))
;;    (org-make-link-string (concat "file:" path) subject)))
;;
;;(defun org-insert-file-link ()
;;  (interactive)
;;  (insert (org-get-file-link)))
;;
;;(defun org-set-file-link ()
;;  "Set a property for the current headline."
;;  (interactive)
;;  (org-set-property "File" (org-get-file-link)))

(defun org-set-dtp-link ()
  "Set a property for the current headline."
  (interactive)
  (org-set-property "Document" (org-get-dtp-link)))

(defun org-dtp-message-open ()
  "Visit the message with the given MESSAGE-ID.
This will use the command `open' with the message URL."
  (interactive)
  (re-search-backward "\\[\\[message://\\(.+?\\)\\]\\[")
  (do-applescript
   (format "tell application \"DEVONthink Pro\"
        set searchResults to search \"%%3C%s%%3E\" within URLs
        open window for record (get beginning of searchResults)
end tell" (match-string 1))))

(fset 'orgify-line
   [?\C-k ?\C-o ?t ?o ?d ?o tab ?\C-y backspace ?\C-a ?l ?\C-u ?\C-n ?\C-n ?\C-n])

(add-hook 'org-log-buffer-setup-hook
          (lambda ()
            (setq fill-column (- fill-column 5))))

;;;   - howm-mode

(setq howm-view-title-header "*") ;; *BEFORE* loading howm!

(add-hook 'org-agenda-mode-hook (lambda () (local-unset-key (kbd "\C-c,"))))
(add-hook 'org-mode-hook (lambda () (local-unset-key (kbd "\C-c,"))))

(when (load "howm" t)
  (add-to-list 'auto-mode-alist '("\\.howm$" . org-mode))

  (defun org-howm-template (&rest ignore-args)
    (format
     "* %%title%%cursor
  :PROPERTIES:
  :ID:       %s  :CREATED:  %s
  :VISIBILITY: all
  :END:
   "
     (shell-command-to-string "uuidgen")
     (format-time-string (org-time-stamp-format t t))))

  (defun move-org-note-to-howm ()
    (interactive)
    (let* ((created
            (save-excursion
              (re-search-forward
               ":CREATED:\\s-*\\[\\(.+?\\)\\]")
              (match-string 1)))
           (path
            (expand-file-name
             (format-time-string "%Y/%m/%Y-%m-%d-%H%M%S.howm"
                                 (apply 'encode-time
                                        (org-parse-time-string created)))
             howm-directory))
           (entry (org-x-parse-entry)))
      (org-x-delete-entry)
      (org-x-clear-state entry)
      (org-x-set-depth entry 1)
      (org-x-set-property entry "VISIBILITY" "all")
      (let ((dir (file-name-directory path)))
        (unless (file-directory-p dir)
          (make-directory dir t))
        (with-current-buffer (find-file-noselect path)
          (erase-buffer)
          (org-x-insert-entry entry)
          (save-buffer)
          (kill-buffer (current-buffer))))))

  (setq howm-template 'org-howm-template)

  (define-key org-mode-map [(control ?c) tab] 'action-lock-magic-return))

;;;   - keybindings

(defvar org-subject-transforms
  '(("\\`\\(Re\\|Fwd\\): "        . "")
    ("\\`{ledger} "           . "")
    ("(#[0-9]+)\\'"               . "")
    ("\\`{\\([0-9]+\\)} New:" . "[[bug:\\1][#\\1]]")
    ("\\`\\[.*? - [A-Za-z]+ #\\([0-9]+\\)\\] (New)" .
     "[[redmine:\\1][#\\1]]")))

(defun convert-dates ()
  (interactive)
  (while (re-search-forward ":Date:\\s-*\\(.+\\)" nil t)
    (let ((date-sent (match-string 1)))
      (goto-char (match-beginning 1))
      (delete-region (match-beginning 1) (match-end 1))
      (insert ?\[ (time-to-org-timestamp
                   (apply 'encode-time
                          (parse-time-string date-sent)) t t)
              ?\]))))

(defun org-smart-capture ()
  (interactive)
  (if (eq major-mode 'gnus-summary-mode)
      (let (message-id subject from date-sent)
        (with-current-buffer gnus-original-article-buffer
          (setq message-id (message-field-value "message-id")
                subject (rfc2047-decode-string (message-field-value "subject"))
                from (rfc2047-decode-string (message-field-value "from"))
                date-sent (message-field-value "date")))
        (org-capture nil "t")
        (dolist (transform org-subject-transforms)
          (setq subject (replace-regexp-in-string (car transform)
                                                  (cdr transform) subject)))
        (save-excursion
          (insert subject))
        (org-set-property "Date"
                          (or date-sent
                              (time-to-org-timestamp
                               (apply 'encode-time
                                      (parse-time-string date-sent)) t t)))
        (org-set-property "Message"
                          (format "[[message://%s][%s]]"
                                  (substring message-id 1 -1)
                                  (subst-char-in-string
                                   ?\[ ?\{ (subst-char-in-string
                                            ?\] ?\} subject))))
        (org-set-property "Submitter" from))
    (org-capture nil "t")))

(defun my-org-todo-done () (interactive) (org-todo "DONE"))
(defun my-org-todo-deferred () (interactive) (org-todo "DEFERRED"))
(defun my-org-todo-someday () (interactive) (org-todo "SOMEDAY"))
(defun my-org-todo-delegated () (interactive) (org-todo "DELEGATED"))
(defun my-org-todo-note () (interactive) (org-todo "NOTE"))
(defun my-org-todo-started () (interactive) (org-todo "STARTED"))
(defun my-org-todo-todo () (interactive) (org-todo "TODO"))
(defun my-org-todo-waiting () (interactive) (org-todo "WAITING"))
(defun my-org-todo-canceled () (interactive) (org-todo "CANCELED"))

(define-key mode-specific-map [?x ?d] 'my-org-todo-done)
(define-key mode-specific-map [?x ?r] 'my-org-todo-deferred)
(define-key mode-specific-map [?x ?y] 'my-org-todo-someday)
(define-key mode-specific-map [?x ?g] 'my-org-todo-delegated)
(define-key mode-specific-map [?x ?n] 'my-org-todo-note)
(define-key mode-specific-map [?x ?s] 'my-org-todo-started)
(define-key mode-specific-map [?x ?t] 'my-org-todo-todo)
(define-key mode-specific-map [?x ?w] 'my-org-todo-waiting)
(define-key mode-specific-map [?x ?x] 'my-org-todo-canceled)

(define-key mode-specific-map [?x ?l] 'org-insert-dtp-link)
(define-key mode-specific-map [?x ?L] 'org-set-dtp-link)

(define-key mode-specific-map [?x ?m] 'org-insert-message-link)
(define-key mode-specific-map [?x ?M] 'org-set-message-link)
;;(define-key mode-specific-map [?x ?a] 'org-insert-apple-message-link)
(define-key mode-specific-map [?x ?Y] 'org-set-message-sender)

(define-key mode-specific-map [?x ?u] 'org-insert-url-link)
(define-key mode-specific-map [?x ?U] 'org-set-url-link)

(define-key mode-specific-map [?x ?f] 'org-insert-file-link)
(define-key mode-specific-map [?x ?F] 'org-set-file-link)

(define-key mode-specific-map [?x ?b] 'ignore)

(eval-after-load "org"
  '(progn
     (org-defkey org-mode-map [(control meta return)]
                 'org-insert-heading-after-current)
     (org-defkey org-mode-map [(control return)] 'other-window)
     (org-defkey org-mode-map [return] 'org-return-indent)))

(defun yas/org-very-safe-expand ()
  (let ((yas/fallback-behavior 'return-nil)) (yas/expand)))

(add-hook 'org-mode-hook
          (lambda ()
            ;; yasnippet (using the new org-cycle hooks)
            (set (make-local-variable 'yas/trigger-key) [tab])
            (add-to-list 'org-tab-first-hook 'yas/org-very-safe-expand)
            (define-key yas/keymap [tab] 'yas/next-field)))

(remove-hook 'kill-emacs-hook 'org-babel-remove-temporary-directory)

;;;   - org-agenda-mode

(dolist (map (list org-agenda-keymap org-agenda-mode-map))
  (define-key map "\C-n" 'next-line)
  (define-key map "\C-p" 'previous-line)

  (define-key map "g" 'org-agenda-redo)
  (define-key map "f" 'org-agenda-date-later)
  (define-key map "b" 'org-agenda-date-earlier)
  (define-key map "r" 'org-agenda-refile)
  (define-key map " " 'org-agenda-tree-to-indirect-buffer)
  (define-key map "F" 'org-agenda-follow-mode)
  (define-key map "q" 'delete-window)
  (define-key map [(meta ?p)] 'org-agenda-earlier)
  (define-key map [(meta ?n)] 'org-agenda-later)

  (define-prefix-command 'org-todo-state-map)
  (define-key map "x" 'org-todo-state-map)

  (defun my-org-agenda-todo-done ()
    (interactive) (org-agenda-todo "DONE"))
  (defun my-org-agenda-todo-deferred ()
    (interactive) (org-agenda-todo "DEFERRED"))
  (defun my-org-agenda-todo-someday ()
    (interactive) (org-agenda-todo "SOMEDAY"))
  (defun my-org-agenda-todo-delegated ()
    (interactive) (org-agenda-todo "DELEGATED"))
  (defun my-org-agenda-todo-note ()
    (interactive) (org-agenda-todo "NOTE"))
  (defun my-org-agenda-todo-started ()
    (interactive) (org-agenda-todo "STARTED"))
  (defun my-org-agenda-todo-todo ()
    (interactive) (org-agenda-todo "TODO"))
  (defun my-org-agenda-todo-waiting ()
    (interactive) (org-agenda-todo "WAITING"))
  (defun my-org-agenda-todo-canceled ()
    (interactive) (org-agenda-todo "CANCELED"))

  (define-key org-todo-state-map "d" 'my-org-agenda-todo-done)
  (define-key org-todo-state-map "r" 'my-org-agenda-todo-deferred)
  (define-key org-todo-state-map "y" 'my-org-agenda-todo-someday)
  (define-key org-todo-state-map "g" 'my-org-agenda-todo-delegated)
  (define-key org-todo-state-map "n" 'my-org-agenda-todo-note)
  (define-key org-todo-state-map "s" 'my-org-agenda-todo-started)
  (define-key org-todo-state-map "t" 'my-org-agenda-todo-todo)
  (define-key org-todo-state-map "w" 'my-org-agenda-todo-waiting)
  (define-key org-todo-state-map "x" 'my-org-agenda-todo-canceled)

  (define-key org-todo-state-map "z" 'ignore))

(defun org-fit-agenda-window ()
  "Fit the window to the buffer size."
  (and (memq org-agenda-window-setup '(reorganize-frame))
       (fboundp 'fit-window-to-buffer)
       (fit-window-to-buffer)))

(defadvice org-agenda-redo (after fit-windows-for-agenda-redo activate)
  "Fit the Org Agenda to its buffer."
  (org-fit-agenda-window))

(defadvice org-agenda (after fit-windows-for-agenda activate)
  "Fit the Org Agenda to its buffer."
  (org-fit-agenda-window))

;;; * Gnus

(require 'gnus)
(require 'gnus-harvest)
(require 'starttls)
(require 'message)
(require 'pgg)

(gnus-harvest-install 'message-x)

(add-hook 'mail-citation-hook 'sc-cite-original)

(add-hook 'gnus-summary-mode-hook
          (lambda ()
            (set (make-local-variable 'hl-line-face) 'underline)
            (hl-line-mode 1)))

(defun start-offlineimap ()
  (interactive)
  (shell-command
   "launchctl load -S Aqua -w ~/Library/LaunchAgents/mac.offlineimap.plist")
  (message "Offlineimap started"))

(defun shutdown-offlineimap ()
  (shell-command
   "launchctl unload -w ~/Library/LaunchAgents/mac.offlineimap.plist")
  (message "Offlineimap stopped"))

(add-hook 'gnus-agent-plugged-hook 'start-offlineimap)
(add-hook 'gnus-agent-unplugged-hook 'shutdown-offlineimap)
(add-hook 'gnus-after-exiting-gnus-hook 'shutdown-offlineimap)

(add-hook 'gnus-startup-hook 'bbdb-insinuate-gnus)
(add-hook 'gnus-startup-hook 'bbdb-insinuate-sc)

(add-hook 'dired-mode-hook 'gnus-dired-mode)

(defun gnus-query (query)
  (interactive "sMail Query: ")
  (let ((nnir-imap-default-search-key "imap"))
    (gnus-group-make-nnir-group
     nil
     `((query    . ,query)
       (criteria . "")
       (server   . "nnimap:Local") ))))

(defun gnus-goto-article (message-id)
  (gnus-query (concat "header message-id " message-id))
  (gnus-summary-refer-article message-id))

(defun gmail-report-spam ()
  "Report the current or marked mails as spam.
This moves them into the Spam folder."
  (interactive)
  (gnus-summary-move-article nil "Spam"))

(defadvice message-goto-from (after insert-boostpro-address activate)
  (if (looking-back ": ")
      (insert "John Wiegley <johnw@boostpro.com>"))
  (goto-char (line-end-position))
  (re-search-backward ": ")
  (goto-char (match-end 0)))

;;;   - Cleanup Gnus buffers on exit

(defun exit-gnus-on-exit ()
  (if (and (fboundp 'gnus-group-exit)
           (gnus-alive-p))
      (with-current-buffer (get-buffer "*Group*")
        (let (gnus-interactive-exit)
          (gnus-group-exit)))))

(add-hook 'kill-emacs-hook 'exit-gnus-on-exit)

;;;   - Scoring

(eval-when-compile
  (defvar arg))

(defun gnus-score-groups ()
  (interactive)
  (save-excursion
    (dolist (info (cdr gnus-newsrc-alist))
      ;; Only consider this group if it's at or below the current level
      (when (<= (gnus-info-level info)
                (if (numberp arg)
                    arg
                  (or (gnus-group-default-level nil t)
                      (gnus-group-default-list-level)
                      gnus-level-subscribed)))
        (let* ((group (gnus-info-group info))
               (unread (gnus-group-unread group)))
          (when (and (not (string= "nnimap+Local:INBOX" group))
                     (numberp unread) (> unread 0))
            (ignore-errors
              (gnus-summary-read-group group nil t))
            (when (and gnus-summary-buffer
                       (buffer-live-p gnus-summary-buffer)
                       (eq (current-buffer)
                           (get-buffer gnus-summary-buffer)))
              (gnus-summary-exit))))))))

;;;   - Summary line format functions

(defsubst dot-gnus-tos (time)
  "Convert TIME to a floating point number."
  (+ (* (car time) 65536.0)
     (cadr time)
     (/ (or (car (cdr (cdr time))) 0) 1000000.0)))

(defun gnus-user-format-function-S (header)
  "Return how much time it's been since something was sent."
  (condition-case err
      (let ((date (mail-header-date header)))
        (if (> (length date) 0)
            (let* ((then (dot-gnus-tos
                          (apply 'encode-time (parse-time-string date))))
                   (now (dot-gnus-tos (current-time)))
                   (diff (- now then)))
              (cond ((>= diff (* 86400.0 7.0 52.0))
                     (if (>= diff (* 86400.0 7.0 52.0 10.0))
                         (format "%3dY" (floor (/ diff (* 86400.0 7.0 52.0))))
                       (format "%3.1fY" (/ diff (* 86400.0 7.0 52.0)))))
                    ((>= diff (* 86400.0 30.0))
                     (if (>= diff (* 86400.0 30.0 10.0))
                         (format "%3dM" (floor (/ diff (* 86400.0 30.0))))
                       (format "%3.1fM" (/ diff (* 86400.0 30.0)))))
                    ((>= diff (* 86400.0 7.0))
                     (if (>= diff (* 86400.0 7.0 10.0))
                         (format "%3dw" (floor (/ diff (* 86400.0 7.0))))
                       (format "%3.1fw" (/ diff (* 86400.0 7.0)))))
                    ((>= diff 86400.0)
                     (if (>= diff (* 86400.0 10.0))
                         (format "%3dd" (floor (/ diff 86400.0)))
                       (format "%3.1fd" (/ diff 86400.0))))
                    ((>= diff 3600.0)
                     (if (>= diff (* 3600.0 10.0))
                         (format "%3dh" (floor (/ diff 3600.0)))
                       (format "%3.1fh" (/ diff 3600.0))))
                    ((>= diff 60.0)
                     (if (>= diff (* 60.0 10.0))
                         (format "%3dm" (floor (/ diff 60.0)))
                       (format "%3.1fm" (/ diff 60.0))))
                    (t
                     (format "%3ds" (floor diff)))))))
    (error "    ")))

(eval-when-compile
  (defvar thread)
  (defvar gnus-tmp-level))

(defun gnus-user-format-function-t (header)
  (let ((tcount (gnus-summary-number-of-articles-in-thread
                 (and (boundp 'thread) (car thread)) gnus-tmp-level)))
    (if (> tcount 1)
        (number-to-string tcount)
      " ")))

(defun gnus-user-format-function-j (headers)
  (let ((to (gnus-extra-header 'To headers)))
    (if (string-match gnus-ignored-from-addresses to)
        (if (string-match "," to) "~" "»")
      (if (string-match gnus-ignored-from-addresses
                        (gnus-extra-header 'Cc headers))
          "~"
        " "))))

(defvar gnus-count-recipients-threshold 5
  "*Number of recipients to consider as large.")

(defun gnus-user-format-function-r (header)
  "Given a Gnus message header, returns priority mark.
If I am the only recipient, return \"!\".
If I am one of a few recipients, but I'm listed in To:, return \"*\".
If I am one of a few recipients, return \"/\".
If I am one of many recipients, return \".\".
Else, return \" \"."
  (let* ((to (or (cdr (assoc 'To (mail-header-extra header))) ""))
         (cc (or (cdr (assoc 'Cc (mail-header-extra header))) "")))
    (cond
     ((string-match gnus-ignored-from-addresses to)
      (let ((len (length (bbdb-split to ","))))
        (cond
         ((and (= len 1) (string= cc "")) "▻")
         ((= len 1) "►")
         ((< len gnus-count-recipients-threshold) "»")
         (t "☀"))))
     ((string-match gnus-ignored-from-addresses
                    (concat to ", " cc))
      (if (< (length (bbdb-split (concat to ", " cc) ","))
             gnus-count-recipients-threshold)
          "·"
        ":"))
     (t " "))))

;;;   - Browsing article URLs

(defun gnus-article-get-urls-region (min max)
  "Return a list of urls found in the region between MIN and MAX"
  (let (url-list)
    (save-excursion
      (save-restriction
        (narrow-to-region min max)
        (goto-char (point-min))
        (while (re-search-forward gnus-button-url-regexp nil t)
          (let ((match-string (match-string-no-properties 0)))
            (if (and (not (equal (substring match-string 0 4) "file"))
                     (not (member match-string url-list)))
                (setq url-list (cons match-string url-list)))))))
    url-list))

(defun gnus-article-get-current-urls ()
  "Return a list of the urls found in the current `gnus-article-buffer'"
  (let (url-list)
    (with-current-buffer gnus-article-buffer
      (setq url-list (gnus-article-get-urls-region (point-min) (point-max))))
    url-list))

(defun gnus-article-browse-urls ()
  "Visit a URL from the `gnus-article-buffer' by prompting via a
    poping up a buffer showing the list of URLs found with the
    `gnus-button-url-regexp'."
  (interactive)
  (gnus-configure-windows 'article)
  (gnus-summary-select-article nil nil 'pseudo)
  (let ((temp-buffer (generate-new-buffer " *Article URLS*"))
        (urls (gnus-article-get-current-urls))
        (this-window (selected-window))
        (browse-window (get-buffer-window gnus-article-buffer))
        (count 0))
    (save-excursion
      (save-window-excursion
        (with-current-buffer temp-buffer
         (mapc (lambda (string)
                 (insert (format "\t%d: %s\n" count string))
                 (setq count (1+ count))) urls)
         (not-modified)
         (pop-to-buffer temp-buffer)
         (setq count
               (string-to-number
                (char-to-string (if (fboundp
                                     'read-char-exclusive)
                                    (read-char-exclusive)
                                  (read-char)))))
         (kill-buffer temp-buffer)))
      (if browse-window
          (progn (select-window browse-window)
                 (browse-url (nth count urls)))))
    (select-window this-window)))

;;;   - Keybindings

(define-key global-map [(alt meta ?f)] 'gnus-query)

(eval-after-load "gnus-group"
  '(progn
     (define-key gnus-group-score-map [?s] 'gnus-score-groups)
     (define-key gnus-group-mode-map [?v ?o] 'start-offlineimap)))

(eval-after-load "gnus-sum"
  '(progn
     (define-key gnus-summary-mode-map [?$] 'gmail-report-spam)
     (define-key gnus-summary-mode-map [?B backspace]
       #'(lambda (arg)
           (interactive "P")
           (if (string-match "\\(drafts\\|queue\\)" gnus-newsgroup-name)
               (gnus-summary-delete-article arg)
             (gnus-summary-move-article arg "[Gmail].Trash"))))
     (define-key gnus-summary-mode-map [(control ?c) (control ?o)]
       'gnus-article-browse-urls)))

(eval-after-load "w3m"
  '(define-key w3m-minor-mode-map "\C-m" 'w3m-view-url-with-external-browser))

;; Local Variables:
;;   mode: emacs-lisp
;;   mode: outline-minor
;;   outline-regexp: "\\(\f\\|;;;\\( +[-*+]\\)\\)"
;; End:

;;; emacs.el ends here
