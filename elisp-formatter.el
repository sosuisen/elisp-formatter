;;; elisp-formatter.el --- Indent Emacs Lisp files as emacs-lisp-mode does -*- lexical-binding: t; -*-

;;; Commentary:

;; Emacs Lisp has no formatter of its own, so Emacs indents it.

;;; Code:

(defun elisp-formatter-formatted (file)
  "Return the text of FILE as the formatter writes it."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(provide 'elisp-formatter)

;;; elisp-formatter.el ends here
