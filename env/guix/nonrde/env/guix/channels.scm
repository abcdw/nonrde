;;; SPDX-FileCopyrightText: 2024, 2025 Andrew Tropin <andrew@trop.in>
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (nonrde env guix channels)
  #:use-module ((rde-configs env guix channels) #:prefix rde-configs:)
  #:use-module (guix channels)
  #:export (core-channels))

(define core-channels
  (cons
   (channel
    (name 'non-guix)
    (url "https://gitlab.com/nonguix/nonguix")
    (branch "master")
    (commit
     "02270b585e7d641afabd86ee6eaf7a6aad2f5df7")
    (introduction
     (make-channel-introduction
      "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
      (openpgp-fingerprint
       "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
   rde-configs:core-channels))

core-channels
