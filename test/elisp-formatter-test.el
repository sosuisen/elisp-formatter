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

;; 字下げのずれた行は、emacs-lisp-modeの字下げに直る。
(ert-deftest elisp-formatter-fixes-a-wrong-indent ()
  (should (equal (elisp-formatter-test--formatted "(defun f (x)\n(when x\n        (message \"%s\" x)))\n")
                 "(defun f (x)\n  (when x\n    (message \"%s\" x)))\n")))

;; 字下げは、タブを使わず空白で行う。
(ert-deftest elisp-formatter-indents-with-spaces-not-tabs ()
  (should (equal (elisp-formatter-test--formatted
                  "(defun f (x)\n  (when x\n    (when x\n      (when x\n(message \"%s\" x)))))\n")
                 "(defun f (x)\n  (when x\n    (when x\n      (when x\n        (message \"%s\" x)))))\n")))

;; 前からある字下げのタブも、空白になる。
(ert-deftest elisp-formatter-turns-the-tabs-of-an-indent-into-spaces ()
  (should (equal (elisp-formatter-test--formatted
                  "(defun f (x)\n  (when x\n    (when x\n      (when x\n\t(message \"%s\" x)))))\n")
                 "(defun f (x)\n  (when x\n    (when x\n      (when x\n        (message \"%s\" x)))))\n")))

;; 文字列の中の行の頭のタブは、そのまま残る。
(ert-deftest elisp-formatter-leaves-a-tab-at-the-start-of-a-line-in-a-string ()
  (let ((text "(defconst c \"first\n\tsecond\")\n"))
    (should (equal (elisp-formatter-test--formatted text) text))))

(provide 'elisp-formatter-test)

;;; elisp-formatter-test.el ends here
