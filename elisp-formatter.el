;;; elisp-formatter.el --- Indent Emacs Lisp files as emacs-lisp-mode does -*- lexical-binding: t; -*-

;;; Commentary:

;; Emacs Lisp has no formatter of its own, so Emacs indents it.

;;; Code:

(defun elisp-formatter-formatted (file)
  "Return the text of FILE as the formatter writes it."
  (with-temp-buffer
    (insert-file-contents file)
    (emacs-lisp-mode)
    (setq indent-tabs-mode nil)
    (let ((inhibit-message t))
      (indent-region (point-min) (point-max)))
    (goto-char (point-min))
    (while (re-search-forward "^[ \t]*\t[ \t]*" nil t)
      (unless (save-excursion (save-match-data (nth 3 (syntax-ppss (match-beginning 0)))))
        (replace-match (make-string (current-column) ?\s))))
    (delete-trailing-whitespace)
    (buffer-string)))

(provide 'elisp-formatter)

;;; elisp-formatter.el ends here
