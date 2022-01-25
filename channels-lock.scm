(use-modules (guix channels))

(list (channel
        (name 'non-guix)
        (url "https://gitlab.com/nonguix/nonguix")
        (branch "master")
        (commit
          "4c0b9a86521a6d06c895b41e62c254da83feff7a"))
      (channel
        (name 'guix)
        (url "file:///home/bob/work/gnu/guix")
        (branch "master")
        (commit
          "ad876e5b13")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
