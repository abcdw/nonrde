(use-modules (guix channels))

(list (channel
        (name 'non-guix)
        (url "https://gitlab.com/nonguix/nonguix")
        (branch "master")
        (commit
          "4399c012e4bb5460c1807285ed98fb5455816f8c"))
      (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (branch "master")
        (commit
          "c2cb1160322c5b18b839b3c2ab0d53fb78793125")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
