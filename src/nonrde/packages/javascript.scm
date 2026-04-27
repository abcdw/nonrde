;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages javascript)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (nonguix build-system binary))

(define-public deno
  (package
   (name "deno")
   (version "2.1.9")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/denoland/deno/releases/download/v"
                  version
                  "/deno-x86_64-unknown-linux-gnu.zip"))
            (sha256
             (base32
              "11kdmk3jk2rfsljg6rid6d65blcl51r6qpq1997h3ipmafy469g4"))))
   (build-system binary-build-system)
   (arguments
    (list
     #:install-plan #~'(("deno" "bin/"))
     #:patchelf-plan #~'(("deno" ("gcc:lib" "glibc")))))
   (inputs `(("gcc:lib" ,gcc "lib")
             ("glibc" ,glibc)))
   (supported-systems '("x86_64-linux"))
   (synopsis "A modern runtime for JavaScript and TypeScript.")
   (description
    "Deno is a JavaScript, TypeScript, and WebAssembly runtime with secure
defaults and a great developer experience. It's built on V8, Rust, and
Tokio.")
   (home-page "https://deno.com")
   (license license:gpl3+)))
