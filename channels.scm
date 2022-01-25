(use-modules (guix ci)
	     (guix channels))

(list ;; (channel-with-substitutes-available

 ;;  "https://ci.guix.gnu.org")
 ;; %default-guix-channel
 (channel
  (name 'guix)
  (url "file:///home/bob/work/gnu/guix")
  (introduction
   (make-channel-introduction
    "9edb3f66fd807b096b48283debdcddccfea34bad"
    (openpgp-fingerprint
     "BBB0 2DDF 2CEA F6A8 0D1D E643 A2A0 6DF2 A33A 54FA"))))
 (channel
  (name 'non-guix)
  (url "https://gitlab.com/nonguix/nonguix")))
