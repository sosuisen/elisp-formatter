;;; elisp-formatter.el --- Indent Emacs Lisp files as emacs-lisp-mode does -*- lexical-binding: t; -*-

;;; Commentary:

;; Emacs Lisp has no formatter of its own, so Emacs indents it.  The indent is the one of
;; `emacs-lisp-mode', with spaces and no tabs, and no space at the end of a line.  Nothing
;; changes inside a string.  A macro of the given files is indented by its `declare' form.
;;
;;   emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-write PATH...
;;   emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-check PATH...
;;
;; See README.md.

;;; Code:

(defun elisp-formatter--in-string-p (position)
  "Return non-nil when POSITION is inside a string."
  (save-excursion
    (save-match-data
      (nth 3 (syntax-ppss position)))))

(defun elisp-formatter--replace-outside-strings (regexp replacement)
  "Replace each match of REGEXP outside a string in the current buffer.
REPLACEMENT is a function that returns the new text.  It runs with the
point at the end of the match."
  (goto-char (point-min))
  (while (re-search-forward regexp nil t)
    (unless (elisp-formatter--in-string-p (match-beginning 0))
      (replace-match (funcall replacement) t t))))

(defun elisp-formatter-files (paths)
  "Return the Emacs Lisp files of PATHS.
A path is a file, or a folder whose `.el' files are all taken."
  (mapcan (lambda (path)
            (if (file-directory-p path)
                (directory-files-recursively path "\\.el\\'")
              (list path)))
          paths))

(defun elisp-formatter-learn-macros (files)
  "Define the macros of FILES, so that the indent follows their `declare' forms.
Only the `defmacro' forms are evaluated: loading the files would run the
rest of them."
  (dolist (file files)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (condition-case nil
          (while t
            (let ((form (read (current-buffer))))
              (when (eq (car-safe form) 'defmacro)
                (eval form t))))
        (end-of-file nil)))))

(defun elisp-formatter-formatted (file)
  "Return the text of FILE as the formatter writes it."
  (with-temp-buffer
    (insert-file-contents file)
    (emacs-lisp-mode)
    (setq indent-tabs-mode nil)
    (let ((inhibit-message t))
      (indent-region (point-min) (point-max)))
    ;; `indent-region' keeps an indent that has the right width, even with tabs in it.
    (elisp-formatter--replace-outside-strings
     "^[ \t]*\t[ \t]*" (lambda () (make-string (current-column) ?\s)))
    (elisp-formatter--replace-outside-strings "[ \t]+$" (lambda () ""))
    (buffer-string)))

(defun elisp-formatter--bytes (formatted)
  "Return FORMATTED as the bytes of a file, in UTF-8 with LF."
  (encode-coding-string formatted 'utf-8-unix))

(defun elisp-formatter--file-bytes (file)
  "Return the bytes of FILE as they are."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (let ((coding-system-for-read 'no-conversion))
      (insert-file-contents file))
    (buffer-string)))

(defun elisp-formatter-changed (paths)
  "Return the files of PATHS that are not formatted, each with its formatted text."
  (let ((files (elisp-formatter-files paths))
        changed)
    (elisp-formatter-learn-macros files)
    (dolist (file files (nreverse changed))
      (let ((formatted (elisp-formatter-formatted file)))
        (unless (equal (elisp-formatter--bytes formatted) (elisp-formatter--file-bytes file))
          (push (cons file formatted) changed))))))

(defconst elisp-formatter--usage
  "Usage:
  emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-write PATH...
  emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-check PATH...
A PATH is an Emacs Lisp file, or a folder whose .el files are all taken."
  "What the commands print when no path is given.")

(defun elisp-formatter--command-paths ()
  "Take the paths that follow the command on the command line.
Without a path, print the usage and end Emacs with 2."
  (let ((paths command-line-args-left))
    (setq command-line-args-left nil)
    (unless paths
      (message "%s" elisp-formatter--usage)
      (kill-emacs 2))
    paths))

(defun elisp-formatter-write ()
  "Format the Emacs Lisp files of the paths on the command line."
  (dolist (entry (elisp-formatter-changed (elisp-formatter--command-paths)))
    (let ((coding-system-for-write 'utf-8-unix))
      (with-temp-file (car entry)
        (insert (cdr entry))))
    (message "formatted %s" (car entry))))

(defun elisp-formatter-check ()
  "Fail when an Emacs Lisp file of the paths on the command line is not formatted."
  (let ((changed (elisp-formatter-changed (elisp-formatter--command-paths))))
    (dolist (entry changed)
      (message "not formatted: %s" (car entry)))
    (when changed
      (kill-emacs 1))))

(provide 'elisp-formatter)

;;; elisp-formatter.el ends here
