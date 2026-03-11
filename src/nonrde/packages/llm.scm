;;; SPDX-License-Identifier: GPL-3.0-or-later
;;;
;;; SPDX-FileCopyrightText: 2026 Franz Geffke <mail@gofranz.com>
;;; SPDX-FileCopyrightText: 2026 Andrew Tropin <andrew@trop.in>

(define-module (nonrde packages llm)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages xorg)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build-system emacs)
  #:use-module (nonguix build-system binary)
  #:use-module (nonguix licenses))

(define-public claude-code
  (package
    (name "claude-code")
    (version "2.1.50")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://storage.googleapis.com/claude-code-dist-"
             "86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/"
             version "/linux-x64/claude"))
       (sha256
        (base32 "0y5y2x1kvf3j10l3bsgjqag66ml91m642rqz3iws8n3w34wjf13l"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:patchelf-plan
      #~'(("claude" ()))
      #:install-plan
      #~'(("claude" "bin/claude-unwrapped"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key inputs #:allow-other-keys)
              (copy-file (assoc-ref inputs "source") "claude")
              (chmod "claude" #o755)))
          (add-after 'install 'create-wrapper
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (unwrapped (string-append bin "/claude-unwrapped"))
                     (wrapper (string-append bin "/claude")))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a
export DISABLE_AUTOUPDATER=1
export DISABLE_INSTALLATION_CHECKS=1
exec ~a \"$@\"
"
                            (search-input-file inputs "bin/bash")
                            unwrapped)))
                (chmod wrapper #o755)))))))
    (inputs
     (list bash-minimal))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/anthropics/claude-code")
    (synopsis "Claude AI assistant for the terminal")
    (description
     "Claude Code is an agentic coding tool that lives in your terminal.
It can understand your codebase, edit files, run terminal commands, and
handle entire workflows.  This package disables auto-updates.")
    (license (nonfree "https://code.claude.com/docs/en/legal-and-compliance"))))


(define-public emacs-claude-code-ide
  ;; Upstream does not make versioned releases.
  (let ((commit "5f12e60c6d2d1802c8c1b7944bbdf935d5db1364"))
    (package
      (name "emacs-claude-code-ide")
      (version "0.2.5")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
                (url "https://github.com/manzaltu/claude-code-ide.el")
                (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "148xcrqff6khpwf8nnadcyvz8h6mk45xz1498k0wbzy80yzd2axn"))))
      (build-system emacs-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (add-before 'check 'set-home
              (lambda _
                (setenv "HOME" (getenv "TMPDIR")))))
        #:test-command
        #~(list "emacs" "-batch"
                "-L" "."
                "-l" "ert"
                "-l" "claude-code-ide-tests.el"
                "--eval"
                ;; Exclude failing test (uncaught throw)
                (string-append
                 "(ert-run-tests-batch-and-exit "
                 "'(not claude-code-ide-mcp-server-test-ws-send-fix))"))))
      (propagated-inputs
       (list emacs-flycheck
             emacs-transient
             emacs-vterm
             emacs-web-server
             emacs-websocket))
      (home-page "https://github.com/manzaltu/claude-code-ide.el")
      (synopsis "Claude Code IDE integration for Emacs")
      (description
       "This package provides native integration with Claude Code
@acronym{CLI, command-line interface} through the @acronym{MCP, Model
Context Protocol}.  It creates a bidirectional bridge between Claude and
Emacs, enabling Claude to leverage Emacs features including @acronym{LSP,
Language Server Protocol}, project management, tree-sitter, and custom
Elisp functions.  Features include automatic project detection and
session management, terminal integration with @code{vterm} or @code{eat},
diagnostic integration with Flycheck and Flymake, advanced diff viewing
with ediff, and an extensible MCP tools server for accessing Emacs
commands such as xref and imenu.")
      (license license:gpl3+))))

(define-public emacs-opencode
  ;; Upstream does not make versioned releases.
  (let ((commit "bf2040494297390667be6380ea84086f6ed1b1ba")
        (revision "0"))
    (package
      (name "emacs-opencode")
      (version (git-version "0.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
                (url "https://codeberg.org/sczi/opencode.el")
                (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1ry9rc5dh0wk18k34q12rdgz4gh1hhm3k96l0wq2vqb2rgfc7dbp"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-magit
             emacs-markdown-mode
             emacs-plz
             emacs-plz-event-source
             emacs-plz-media-type))
      (home-page "https://codeberg.org/sczi/opencode.el")
      (synopsis "Emacs interface to OpenCode")
      (description
       "This package provides an Emacs UI to OpenCode, an open source AI
coding agent.  It offers integration with Emacs through comint-mode,
vtable, diff-mode, and markdown-mode.  Features include the ability to
add any Emacs buffer to chat context, integration with Magit for
creating new git branches and worktrees, session management, and a
notification system for async operations.")
      (license license:gpl3+))))

(define-public ollama
  (package
    (name "ollama")
    (version "0.15.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ollama/ollama/releases/download/v"
             version "/ollama-linux-amd64.tar.zst"))
       (sha256
        (base32 "0avf2m7b58ps2xy3jc41l7njq2xnxfmfb69cwicc35rvrbiswps4"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:patchelf-plan
      #~'(("bin/ollama" ("glibc" "gcc")))
      #:install-plan
      #~'(("bin/ollama" "bin/"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key inputs #:allow-other-keys)
              (invoke "tar" "--use-compress-program=zstd" "-xf"
                      (assoc-ref inputs "source")))))))
    (native-inputs
     (list zstd))
    (inputs
     (list glibc
           `(,gcc "lib")))
    (supported-systems '("x86_64-linux"))
    (home-page "https://ollama.com")
    (synopsis "Run large language models locally")
    (description
     "Ollama allows you to run large language models locally.
It provides a simple API for creating, running and managing models,
as well as a library of pre-built models that can be easily used.")
    (license license:expat)))

(define-public opencode-bin
  (package
    (name "opencode-bin")
    (version "1.1.60")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/anomalyco/opencode/"
                            "releases/download/v" version
                            "/opencode-linux-x64.tar.gz"))
        (sha256
         (base32 "014672i7xyp2r5d3zfipsk9xi9fpk2gnfaiv4xwkigcrwrcb33hk"))))
    (supported-systems (list "x86_64-linux"))
    (build-system binary-build-system)
    (arguments
      (list
        #:patchelf-plan #~'()
        #:strip-binaries? #f
        #:validate-runpath? #f
        #:phases
        #~(modify-phases %standard-phases
          (add-after 'install 'patch-and-wrap
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (orig (string-append out "/opencode"))
                     (bash (search-input-file inputs "bin/bash"))
                     (patchelf (search-input-file inputs "bin/patchelf"))
                     (ld.so (search-input-file inputs "lib/ld-linux-x86-64.so.2"))
                     (libpath (string-join
                                (list (string-append (assoc-ref inputs "gcc") "/lib")
                                      (string-append (assoc-ref inputs "glibc") "/lib")
                                      (string-append (assoc-ref inputs "libx11") "/lib")
                                      (string-append (assoc-ref inputs "mesa") "/lib"))
                                ":")))
                ;; Only patch interpreter; full patchelf corrupts this binary.
                (invoke patchelf "--set-interpreter" ld.so orig)
                (rename-file orig (string-append orig ".real"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/opencode")
                  (lambda (port)
                    (format port "#!~a
export LD_LIBRARY_PATH=~a${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH
exec ~a.real \"$@\"~%"
                            bash libpath orig)))
                (chmod (string-append bin "/opencode") #o755)))))))
    (native-inputs
      (list patchelf))
    (inputs
      (list
        bash-minimal
        `(,gcc "lib")
        libx11
        glibc
        mesa))
    (home-page "https://opencode.ai")
    (synopsis "the open source AI coding agent.")
    (description "OpenCode is an open source agent that helps you write code in your terminal.")
    (license license:expat)))

(define-public pi-coding-agent
  (package
    (name "pi-coding-agent")
    (version "0.56.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/badlogic/pi-mono/releases/download/v"
             version "/pi-linux-x64.tar.gz"))
       (sha256
        (base32 "1xgk3ddbz7plvc5z2siknfqrjq011gh5j9y23a2xrj96pq018rri"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:patchelf-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-and-wrap
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (orig (string-append out "/pi"))
                     (bash (search-input-file inputs "bin/bash"))
                     (patchelf (search-input-file inputs "bin/patchelf"))
                     (ld.so (search-input-file
                             inputs "lib/ld-linux-x86-64.so.2"))
                     (libpath (string-append
                               (assoc-ref inputs "glibc") "/lib")))
                (invoke patchelf "--set-interpreter" ld.so orig)
                (rename-file orig (string-append orig ".real"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/pi")
                  (lambda (port)
                    (format port "#!~a
export LD_LIBRARY_PATH=~a${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH
exec ~a.real \"$@\"~%"
                            bash libpath orig)))
                (chmod (string-append bin "/pi") #o755)))))))
    (native-inputs
     (list patchelf))
    (inputs
     (list bash-minimal glibc))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/badlogic/pi-mono")
    (synopsis "AI coding agent for the terminal")
    (description
     "Pi is an interactive coding agent CLI with read, bash, edit, and write
tools and session management.  It supports multiple LLM providers and can
be extended with skills, prompt templates, and extensions.")
    (license license:expat)))

(define-public ollama
  (package
    (name "ollama")
    (version "0.17.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ollama/ollama/releases/download/v"
             version "/ollama-linux-amd64.tar.zst"))
       (sha256
        (base32 "078ar2v457wbvv6ns7i70vy6ycxrv7lfnzfprs9j9yk6kw71xjji"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:patchelf-plan
      #~'(("bin/ollama" ("glibc" "gcc")))
      #:install-plan
      #~'(("bin/ollama" "bin/"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key inputs #:allow-other-keys)
              (invoke "tar" "--use-compress-program=zstd" "-xf"
                      (assoc-ref inputs "source")))))))
    (native-inputs
     (list zstd))
    (inputs
     (list glibc
           `(,gcc "lib")))
    (supported-systems '("x86_64-linux"))
    (home-page "https://ollama.com")
    (synopsis "Run large language models locally")
    (description
     "Ollama allows you to run large language models locally.
It provides a simple API for creating, running and managing models,
as well as a library of pre-built models that can be easily used.")
    (license license:expat)))

;; ((@ (rde api store) build) opencode-bin)
