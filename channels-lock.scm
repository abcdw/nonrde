(list (channel
        (name 'non-guix)
        (url "https://gitlab.com/nonguix/nonguix")
        (commit
          "9b8e36975bd0dd81d47d8b06da4beffe8bac3a50"))
      (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (commit
          "946dd6103a843b48e828addae53c240077c2221a")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
