;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages networking)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages gcc)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (nonguix build-system binary))

(define-public shadowsocks-rust
  (package
    (name "shadowsocks-rust")
    (version "1.23.5")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/shadowsocks/shadowsocks-rust/releases/download/v"
                    version
                    "/shadowsocks-v" version ".x86_64-unknown-linux-gnu.tar.xz"))
              (sha256
               (base32
                "0q089rnidfzfcwxz9vwjl4dxirrgidsav5433z3g2r1x9bscvlgr"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:install-plan #~'(("sslocal" "bin/")
                         ("ssmanager" "bin/")
                         ("ssservice" "bin/")
                         ("ssserver" "bin/")
                         ("ssurl" "bin/"))
      #:patchelf-plan #~'(("sslocal" ("gcc:lib"))
                          ("ssserver" ("gcc:lib"))
                          ("ssmanager" ("gcc:lib"))
                          ("ssservice" ("gcc:lib"))
                          ("ssurl" ("gcc:lib")))))
    (inputs `(("gcc:lib" ,gcc "lib")))
    (supported-systems '("x86_64-linux"))
    (synopsis "High-performance, multiplayer code editor")
    (description
     "Zed, a high-performance, multiplayer code editor from the creators of
Atom and Tree-sitter.")
    (home-page "zed.dev")
    (license license:gpl3+)))
