;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages android)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages video)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages sdl)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system meson)
  #:use-module (nonguix build-system binary))

(define-public scrcpy-server
  (package
    (name "scrcpy-server")
    (version "3.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Genymobile/scrcpy/releases/download/v"
                    version
                    "/scrcpy-linux-x86_64-v" version ".tar.gz"))
              (sha256
               (base32
                "16n50jxi0jrdsarz5sgir6p298cf3gv34m7rz2rcd7pdj90abnrp"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:install-plan #~'(("scrcpy-server" ""))))
    (supported-systems '("x86_64-linux"))
    (synopsis "A modern runtime for JavaScript and TypeScript.")
    (description
     "Deno is a JavaScript, TypeScript, and WebAssembly runtime with secure
defaults and a great developer experience. It's built on V8, Rust, and
Tokio.")
    (home-page "https://deno.com")
    (license license:gpl3+)))

(define-public scrcpy
  (package
    (name "scrcpy")
    (version "3.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/Genymobile/scrcpy")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0janx96lv15673yfn3zys1x5i70463icmxg3qcgdkapgbp0fa6sz"))))
    (build-system meson-build-system)
    (native-inputs
     (list pkg-config))
    (inputs
     (list sdl2 libusb ffmpeg scrcpy-server))
    (arguments
     `(#:tests? #f
       #:phases (modify-phases %standard-phases
                  (add-after 'unpack 'disable-server-build
                    ;; because server build need android ndk
                    ;; you can use SCRCPY_SERVER_PATH to instead default server binary
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (mkdir-p
                       (string-append
                        (assoc-ref outputs "out") "/share/scrcpy"))
                      (copy-file
                       (search-input-file inputs "scrcpy-server")
                       (string-append (assoc-ref outputs "out")
                                      "/share/scrcpy/scrcpy-server"))
                      (truncate-file "server/meson.build" 0))))))
    (home-page "https://github.com/Genymobile/scrcpy")
    (synopsis "Display and control your Android device")
    (description "This application provides display and control
of Android devices connected via USB or over TCP/IP.")
    (license license:asl2.0)))
