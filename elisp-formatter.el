;;; elisp-formatter.el --- Indent Emacs Lisp files as emacs-lisp-mode does -*- lexical-binding: t; -*-

;;; Commentary:

;; Emacs Lisp has no formatter of its own, so Emacs indents it.

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

(provide 'elisp-formatter)

;;; elisp-formatter.el ends here
