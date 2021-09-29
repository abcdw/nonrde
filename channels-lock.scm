(list (channel
        (name 'non-guix)
        (url "https://gitlab.com/nonguix/nonguix")
        (commit
          "c93654cc7f99e15d5c1252d98e0bbf14e79e7de9"))
      (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (commit
          "4687ee9cacae7dcc63d44365062de30e20da8b0e")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
