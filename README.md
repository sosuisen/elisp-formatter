# elisp-formatter

Indent Emacs Lisp files as `emacs-lisp-mode` does, from the command line and in CI.

Emacs Lisp has no formatter of its own. This one uses the indent of Emacs itself, so TAB in
Emacs gives the same result. It changes only the space at the start and at the end of a line.
It does not break or join lines.

- The indent is the one of `emacs-lisp-mode`, with spaces and no tabs.
- The spaces at the end of a line are removed.
- Inside a string, nothing changes.
- A macro in the given files is indented by its `declare (indent ...)` form. Only the
  `defmacro` forms are evaluated. The rest of the files does not run.
- A file is written in UTF-8 with LF. A file that is already formatted is not written.

## Usage

```
emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-write PATH...
emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-check PATH...
```

A PATH is an Emacs Lisp file, or a folder whose `.el` files are all taken.

| Command | What it does | Exit code |
|---|---|---|
| `elisp-formatter-write` | Formats the files | 0 |
| `elisp-formatter-check` | Changes nothing, and names the files that are not formatted | 0 when all are formatted, 1 otherwise |

Without a PATH, both print the usage and end with 2.

A quoted list of symbols is indented like a call: its lines go under the second element. To keep
them under the first one, put the first symbol alone on the first line.

```elisp
'(first
  second third)
```

## In a project

On a development machine, clone this repository once, and run the commands from any project.

```
git clone git@github.com:sosuisen/elisp-formatter.git
```

In CI, fetch a tag of this repository. It is private, so the job needs a token that can read
it. Put a fine-grained personal access token with read access to the contents of this
repository in a secret of the project, here `ELISP_FORMATTER_TOKEN`.

```yaml
- uses: actions/checkout@v4
  with:
    repository: sosuisen/elisp-formatter
    ref: v0.1.0
    path: elisp-formatter
    token: ${{ secrets.ELISP_FORMATTER_TOKEN }}
- run: emacs -Q --batch -l elisp-formatter/elisp-formatter.el -f elisp-formatter-check lisp
```

## Tests

```
emacs -Q --batch -L . -l test/elisp-formatter-test.el -f ert-run-tests-batch-and-exit
emacs -Q --batch -l elisp-formatter.el -f elisp-formatter-check elisp-formatter.el test
```

## Release

The version is the Git tag alone, such as `v0.1.0`. No file holds it. A project picks a
version by the tag it fetches.

```
git tag v0.1.0
git push origin v0.1.0
```
