;; This is an operating system configuration template
;; for a "desktop" setup with GNOME and Xfce where the
;; root partition is encrypted with LUKS.

(use-modules (gnu) (guix) (srfi srfi-1))
(use-modules (gnu) (gnu system nss))
(use-modules (nongnu packages linux)
	     (nongnu system linux-initrd))
(use-modules ((rde system desktop) #:prefix rde-desktop:))
(use-service-modules desktop xorg networking)
(use-package-modules certs gnome terminals emacs fonts emacs-xyz guile
		     xorg tmux wm suckless admin)

(operating-system
 (inherit rde-desktop:os)
 (host-name "ixy")
 (timezone "Europe/Moscow")
 (locale "en_US.utf8")

 (keyboard-layout
  (keyboard-layout "us,ru" "dvorak,"
		   #:options '("grp:win_space_toggle" "ctrl:nocaps")))

 (kernel linux)
 (firmware (cons*
	    ;; iwlwifi-firmware
	    linux-firmware
            %base-firmware))

 ;; (users (cons (user-account
 ;;               (name "abcdw")
 ;;               (password "")                     ;no password
 ;;               (group "users")
 ;;               (supplementary-groups '("wheel" "netdev"
 ;;                                       "audio" "video")))
 ;; 	      %base-user-accounts))
 )
