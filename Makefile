GUIX=./pre-inst-env guix

build:
	${GUIX} time-machine -C ./channels-lock.scm -- \
	system build ./ixy.scm

init:
	${GUIX} system init ./ixy.scm /mnt

reconfigure:
	sudo -E ${GUIX} time-machine -C ./channels-lock.scm -- \
	system reconfigure --allow-downgrades ./ixy.scm


install: reconfigure

iso:
	${GUIX} time-machine -C ./channels-lock.scm -- \
	system disk-image ./ixy.scm

channels-update-lock:
	echo -e "(use-modules (guix channels))\n" > channels-lock-tmp.scm
	${GUIX} time-machine -C ./channels.scm -- \
	describe -f channels >> channels-lock-tmp.scm
	cat channels-lock-tmp.scm > channels-lock.scm
	rm channels-lock-tmp.scm
