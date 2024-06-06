(use-modules (rde-configs configs)
             (rde features)
             (rde features base)
             (rde features system)

             (srfi srfi-1)
             (ice-9 match)
             (guix gexp)
             (gnu packages linux)

             (nongnu packages linux)
             (nongnu system linux-initrd))

(define nonguix-pub (local-file "../files/keys/nonguix-key.pub"))

(define (unfree-kernel config)
  (define cleaned-features
    (remove (lambda (f)
              (member (feature-name f) (list 'base-services 'kernel)))
            (rde-config-features config)))
  (rde-config
   (inherit config)
   (features
    (append
     (list
      (feature-kernel
       #:kernel linux
       #:kernel-arguments '("snd_hda_intel.dmic_detect=0")
       #:firmware (list
                   iwlwifi-firmware
                   i915-firmware
                   ibt-hw-firmware
                   ;; linux-firmware
                   ))
      (feature-base-services
       ;; TODO: Use substitute-urls directly for guix commands?
       #:default-substitute-urls (list "https://bordeaux.guix.gnu.org"
                                       "https://ci.guix.gnu.org")
       #:guix-substitute-urls (list "https://substitutes.nonguix.org")
       #:guix-authorized-keys (list nonguix-pub)))
     cleaned-features))))

(define ixy-unfree-config
  (unfree-kernel ixy-config))

(define ixy-os
  (rde-config-operating-system ixy-unfree-config))

(define live-unfree-config
  (unfree-kernel live-config))

(define live-os
  (rde-config-operating-system live-unfree-config))

(define (dispatcher)
  (let ((rde-target (getenv "RDE_TARGET")))
    (match rde-target
      ("live-system" live-os)
      ("ixy-system" ixy-os)
      (_ ixy-os))))

(dispatcher)
