;;; SPDX-License-Identifier: GPL-3.0-or-later
;;;
;;; SPDX-FileCopyrightText: 2026 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages code-analysis)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (nonguix build-system binary))

(define-public ast-grep
  (package
    (name "ast-grep")
    (version "0.42.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ast-grep/ast-grep/releases/download/"
             version "/app-x86_64-unknown-linux-gnu.zip"))
       (sha256
        (base32 "0lb6c2wa8frjrjirlzfhgj5h0vdxka6cri3nj36w9g7h0dba09g8"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:install-plan #~'(("ast-grep" "bin/")
                         ("sg" "bin/"))
      #:patchelf-plan #~'(("ast-grep" ("glibc" "gcc:lib"))
                          ("sg" ("glibc" "gcc:lib")))))
    (native-inputs (list unzip))
    (inputs `(("gcc:lib" ,gcc "lib")
              ("glibc" ,glibc)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://ast-grep.github.io/")
    (synopsis "Fast structural code search, lint, and rewriting using AST patterns")
    (description
     "ast-grep (@command{sg}) is a CLI tool for code structural search, lint,
and rewriting based on abstract syntax trees (AST).  Think of it as
@command{grep} but understanding code structure rather than text patterns.
It supports many languages including JavaScript, TypeScript, Python, Rust, Go,
Java, C, C++, and more.")
    (license license:expat)))
