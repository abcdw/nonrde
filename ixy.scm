(use-modules (rde examples abcdw configs)
	     (rde features)
	     (rde features base)
	     (rde features system)

	     (srfi srfi-1)
	     (guix gexp)
	     (gnu packages linux)

	     (nongnu packages linux)
	     (nongnu system linux-initrd))

(define ixy-cleaned-features
  (remove (lambda (f)
	    (member (feature-name f) (list 'base-services 'kernel)))
	  (rde-config-features ixy-config)))

(define ixy-unfree-config
  (rde-config
   (inherit ixy-config)
   (features
    (append
     (list
      (feature-kernel
       #:kernel linux
       #:kernel-loadable-modules (list v4l2loopback-linux-module)
       #:kernel-arguments '("snd_hda_intel.dmic_detect=0")
       #:firmware (list linux-firmware))
      (feature-base-services
       #:guix-substitute-urls (list "https://mirror.brielmaier.net")
       #:guix-authorized-keys (list (local-file "./mirror.brielmaier.net.pub"))))
     ixy-cleaned-features))))

(rde-config-operating-system ixy-unfree-config)
