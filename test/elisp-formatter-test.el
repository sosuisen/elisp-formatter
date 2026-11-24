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

;; 行の終わりの空白は、消える。
(ert-deftest elisp-formatter-removes-the-spaces-at-the-end-of-a-line ()
  (should (equal (elisp-formatter-test--formatted "(defun f (x)  \n  (when x\t\n    x))\n")
                 "(defun f (x)\n  (when x\n    x))\n")))

;; 文字列の中の行の終わりの空白は、そのまま残る。
(ert-deftest elisp-formatter-leaves-the-spaces-at-the-end-of-a-line-in-a-string ()
  (let ((text "(defconst c \"first  \nsecond\")\n"))
    (should (equal (elisp-formatter-test--formatted text) text))))

;; 渡したファイルのマクロは、その`declare'の字下げに従う。
(ert-deftest elisp-formatter-indents-a-macro-by-its-declare-form ()
  (let ((file (make-temp-file
               "elisp-formatter-test" nil ".el"
               (concat "(defmacro elisp-formatter-test--with-two (a b &rest body)\n"
                       "  (declare (indent 2))\n"
                       "  `(list ,a ,b ,@body))\n"
                       "(elisp-formatter-test--with-two 1\n"
                       "2\n"
                       "3)\n"))))
    (unwind-protect
        (progn
          (elisp-formatter-learn-macros (list file))
          (should (string-suffix-p "(elisp-formatter-test--with-two 1\n    2\n  3)\n"
                                   (elisp-formatter-formatted file))))
      (delete-file file))))

(defvar elisp-formatter-test--ran nil
  "Set by a form in a file whose macros are learned.")

;; マクロを覚えるとき、defmacroのほかの式は評価しない。
(ert-deftest elisp-formatter-learns-the-macros-without-running-the-other-forms ()
  (let ((file (make-temp-file "elisp-formatter-test" nil ".el"
                              "(setq elisp-formatter-test--ran t)\n"))
        (elisp-formatter-test--ran nil))
    (unwind-protect
        (progn
          (elisp-formatter-learn-macros (list file))
          (should-not elisp-formatter-test--ran))
      (delete-file file))))

(defmacro elisp-formatter-test--in-folder (names &rest body)
  "Run BODY in a new folder that holds the empty files NAMES.
A name may have a folder in it, which is made."
  (declare (indent 1))
  `(let ((default-directory (file-name-as-directory (make-temp-file "elisp-formatter-test" t))))
     (unwind-protect
         (progn
           (dolist (name ,names)
             (make-empty-file name t))
           ,@body)
       (delete-directory default-directory t))))

(defun elisp-formatter-test--relative (files)
  "Return FILES relative to the current folder, sorted."
  (sort (mapcar #'file-relative-name files) #'string<))

;; フォルダーを渡すと、その下の.elのファイルがすべて対象になる。
(ert-deftest elisp-formatter-takes-all-the-el-files-under-a-folder ()
  (elisp-formatter-test--in-folder '("lisp/a.el" "lisp/test/b.el" "lisp/notes.txt")
    (should (equal (elisp-formatter-test--relative (elisp-formatter-files '("lisp")))
                   '("lisp/a.el" "lisp/test/b.el")))))

(provide 'elisp-formatter-test)

;;; elisp-formatter-test.el ends here
