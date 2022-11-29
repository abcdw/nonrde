(use-modules (guix channels))

(list (channel
        (name 'non-guix)
        (url "https://gitlab.com/nonguix/nonguix")
        (branch "master")
        (commit
          "dfc2b256ebe208605c7da1b35ab0bfd8304ae675")
        (introduction
          (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
              "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
        (name 'guix)
        (url "file:///home/bob/work/gnu/guix")
        (branch "master")
        (commit
          "4b68dcfe41347df7ac11e51f45efd5db9783eb94")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
