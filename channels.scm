(define (local-or-remote-url local-channel-name remote-channel-url)
  (let* ((local-channel-path
          (lambda (channel-name)
            (string-append (getenv "HOME")
                           "/work/"
                           channel-name)))
         (local-channel-git-path
          (lambda (channel-name)
            (string-append "file://"
                           (local-channel-path
                            channel-name)))))
    (if (file-exists? (local-channel-path local-channel-name))
        (local-channel-git-path local-channel-name)
        remote-channel-url)))

(define (local-or-remote-channel channel-name remote-channel-url)
  (channel
   (name (string->symbol channel-name))
   (url
    (local-or-remote-url channel-name remote-channel-url))))

(define extra-channels
  (lambda extra-channels
    (append extra-channels
            %default-channels)))

;; (local-or-remote-channel "rde" "https://github.com/abcdw/rde")

(list
 (channel
  (name 'guix)
  (url "https://git.savannah.gnu.org/git/guix.git"))
 (channel
  (name 'rde)
  (url "https://github.com/abcdw/rde"))
 (channel
  (name 'non-guix)
  (url "https://gitlab.com/nonguix/nonguix")))

