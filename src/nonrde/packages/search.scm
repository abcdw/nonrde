;;; SPDX-License-Identifier: GPL-3.0-or-later
;;;
;;; SPDX-FileCopyrightText: 2026 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages search)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages time)
  #:use-module (gnu packages serialization)
  #:use-module (guix build-system python)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public python-httpx-socks
  (package
    (name "python-httpx-socks")
    (version "0.10.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "httpx_socks" version))
       (sha256
        (base32 "15hh3az6qgykjkcc4p7zw2alpfxab70vnx3ir9wwqyfyfh8y6cp2"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (native-inputs
     (list python-setuptools))
    (propagated-inputs
     (list python-httpx python-socks))
    (home-page "https://github.com/romis2012/httpx-socks")
    (synopsis "SOCKS proxy support for httpx")
    (description
     "This package provides SOCKS4, SOCKS5, and HTTP proxy support for
the Python httpx library, with both sync and async interfaces.")
    (license license:asl2.0)))

(define-public searxng
  (let ((commit "8b95b2058be41580270f1dc348847c3342ee129b")
        (revision "0")
        (base-version "2026.3.10"))
    (package
      (name "searxng")
      (version (git-version base-version revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/searxng/searxng")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1fca95gjgh6j537zqfq3bxiyp9f0f8ib2b7vjaky9k7qd2lmz1z4"))))
      (build-system pyproject-build-system)
      (arguments
       (list
        #:tests? #f
        #:phases
        #~(modify-phases %standard-phases
            (delete 'sanity-check)
            (add-before 'build 'relax-requirements
              (lambda _
                (substitute* "setup.py"
                  (("install_requires=.*") "install_requires=[],"))))
            (add-before 'build 'create-version-file
              (lambda _
                (let ((short-commit (string-take #$commit 8)))
                  (call-with-output-file "searx/version_frozen.py"
                    (lambda (port)
                      (format port "\
VERSION_STRING = \"~a+~a\"
VERSION_TAG = \"~a\"
DOCKER_TAG = \"~a-~a\"
GIT_URL = \"https://github.com/searxng/searxng\"
GIT_BRANCH = \"master\"~%"
                              #$base-version short-commit
                              #$base-version
                              #$base-version short-commit))))))
            (add-after 'install 'install-settings
              (lambda* (#:key outputs #:allow-other-keys)
                (let ((etc (string-append (assoc-ref outputs "out")
                                          "/etc/searxng")))
                  (mkdir-p etc)
                  (copy-file "searx/settings.yml"
                             (string-append etc "/settings.yml"))))))))
      (native-inputs
       (list python-setuptools))
      (propagated-inputs
       (list python-babel
             python-certifi
             python-cloudscraper
             python-dateutil
             python-flask
             python-flask-babel
             python-h2
             python-httpx
             python-httpx-socks
             python-isodate
             python-jinja2
             python-lxml
             python-markdown-it-py
             python-msgspec
             python-pygments
             python-pyyaml
             python-sniffio
             python-typer
             python-typing-extensions
             python-valkey
             python-whitenoise))
      (home-page "https://docs.searxng.org")
      (synopsis "Privacy-respecting metasearch engine")
      (description
       "SearXNG is a privacy-respecting, hackable metasearch engine that
aggregates results from more than 70 search services.  Users are neither
tracked nor profiled.  It can be used over Tor for online anonymity.")
      (license license:agpl3+))))
