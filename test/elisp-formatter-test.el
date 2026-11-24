;;; elisp-formatter-test.el --- Tests of elisp-formatter -*- lexical-binding: t; -*-

;;; Commentary:

;; emacs -Q --batch -L . -l test/elisp-formatter-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'elisp-formatter)

(defun elisp-formatter-test--formatted (text)
  "Return TEXT as the formatter writes it, through a file of its own."
  (let ((file (make-temp-file "elisp-formatter-test" nil ".el" text)))
    (unwind-protect
        (elisp-formatter-formatted file)
      (delete-file file))))

;; emacs-lisp-modeの字下げで整った文は、そのまま残る。
(ert-deftest elisp-formatter-leaves-a-well-indented-text-as-it-is ()
  (let ((text "(defun f (x)\n  (when x\n    (message \"%s\" x)))\n"))
    (should (equal (elisp-formatter-test--formatted text) text))))

(provide 'elisp-formatter-test)

;;; elisp-formatter-test.el ends here
