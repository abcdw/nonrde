(use-modules (rde-configs configs)
             (rde features)
             (rde features base)
             (rde features system)

             (srfi srfi-1)
             (ice-9 match)
             (guix gexp)
             (gnu packages linux)
             (gnu services base)
             (nongnu packages linux)
             (nongnu system linux-initrd))

(define nonguix-pub (local-file "../files/keys/nonguix-key.pub"))

(define (feature-nonguix-substitutes)
  (define (get-system-services _)
    (list
     (simple-service
      'nonguix-substitutes
      guix-service-type
      (guix-extension
       (substitute-urls (list "https://substitutes.nonguix.org"))
       (authorized-keys (list nonguix-pub))))))

  (feature
   (name 'nonguix-substitutes)
   (system-services-getter get-system-services)))

(define (unfree-kernel config)
  (define cleaned-features
    (remove (lambda (f)
              (member (feature-name f) (list 'kernel)))
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
      (feature-nonguix-substitutes))
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
