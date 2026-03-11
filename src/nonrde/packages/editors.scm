;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2024, 2025 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages editors)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gtk)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (nonguix build-system binary)
  #:export (zed lapce))

(define-public zed
  (package
   (name "zed")
   (version "0.176.3")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/zed-industries/zed/releases/download/v"
                  version
                  "/zed-linux-x86_64.tar.gz"))
            (sha256
             (base32
              "11f5585b5iqsrc81rbn5476bijavy2nq1j1j6y8h8sychqpfl13a"))))
   (build-system binary-build-system)
   (arguments
    (list
     #:install-plan #~'(("bin/zed" "bin/")
                        ("libexec/zed-editor" "libexec/"))
     #:patchelf-plan #~'(("bin/zed" ("gcc:lib"))
                         ("libexec/zed-editor"
                          ("glibc"
                           "gcc:lib"
                           "libxkbcommon"
                           "wayland" "vulkan-loader"
                           "alsa-lib"
                           "libxcb"
                           "openssl"
                           "freetype"
                           "fontconfig"
                           "zstd"
                           "zlib")))))
   (inputs `(("gcc:lib" ,gcc "lib")
             ("glibc" ,glibc)
             ("libxkbcommon" ,libxkbcommon)
             ("alsa-lib" ,alsa-lib)
             ("zstd" ,zstd "lib")
             ("zlib" ,zlib)
             ("vulkan-loader" ,vulkan-loader)
             ("wayland" ,wayland)
             ("openssl" ,openssl-1.1)
             ("libxcb" ,libxcb)
             ("freetype" ,freetype)
             ("fontconfig" ,fontconfig)))
   (supported-systems '("x86_64-linux"))
   (synopsis "High-performance, multiplayer code editor")
   (description
    "Zed, a high-performance, multiplayer code editor from the creators of
Atom and Tree-sitter.")
   (home-page "zed.dev")
   (license license:gpl3+)))

(define-public lapce
  (package
   (name "lapce")
   (version "0.4.6")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/lapce/lapce/releases/download/v"
                  version
                  "/lapce-linux-amd64.tar.gz"))
            (sha256
             (base32
              "11091ljk5xlsk344w7mnd58abj2gcdfsq1ds2rrj1gibhvk4a2bs"))))
   (build-system binary-build-system)
   (arguments
    (list
     #:install-plan #~'(("lapce" "bin/"))
     #:patchelf-plan #~'(("lapce"
                          ("glibc"
                           "gcc:lib"
                           "libxkbcommon"
                           "libx11"
                           "libxi"
                           "libxcb"
                           "wayland"
                           "mesa")))
     #:phases
     #~(modify-phases %standard-phases
         (add-after 'install 'create-fontconfig
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (fontconfig (assoc-ref inputs "fontconfig"))
                    (fonts-conf (string-append out "/etc/fonts/fonts.conf"))
                    (conf-dir (string-append fontconfig "/etc/fonts/conf.d")))
               (mkdir-p (string-append out "/etc/fonts"))
               (call-with-output-file fonts-conf
                 (lambda (port)
                   (format port "<?xml version=\"1.0\"?>
<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">
<fontconfig>
  <dir>~a</dir>
  <dir prefix=\"xdg\">fonts</dir>
  <dir>~/.fonts</dir>
  <include ignore_missing=\"yes\">~a</include>
  <include ignore_missing=\"yes\" prefix=\"xdg\">fontconfig/fonts.conf</include>
</fontconfig>~%"
                           (string-append
                            (assoc-ref inputs "font-dejavu")
                            "/share/fonts")
                           conf-dir))))))
         (add-after 'create-fontconfig 'wrap-lapce
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (wrap-program (string-append out "/bin/lapce")
                 `("FONTCONFIG_FILE" = (,(string-append out "/etc/fonts/fonts.conf"))))))))))
   (inputs `(("gcc:lib" ,gcc "lib")
             ("glibc" ,glibc)
             ("libxkbcommon" ,libxkbcommon)
             ("libx11" ,libx11)
             ("libxi" ,libxi)
             ("libxcb" ,libxcb)
             ("wayland" ,wayland)
             ("mesa" ,mesa)
             ("fontconfig" ,fontconfig)
             ("font-dejavu" ,font-dejavu)))
   (supported-systems '("x86_64-linux"))
   (synopsis "Lightning-fast and powerful code editor")
   (description
    "Lapce is a lightning-fast and powerful code editor written in Rust with a
built-in terminal emulator and support for modal editing.")
   (home-page "https://lapce.dev")
   (license license:asl2.0)))
