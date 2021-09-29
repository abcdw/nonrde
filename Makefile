build:
	guix time-machine -C ./channels-lock.scm -- \
	system -L ../rde build ./ixy.scm

reconfigure:
	sudo guix time-machine -C ./channels-lock.scm -- \
	system -L ../rde reconfigure ./ixy.scm

install: reconfigure

iso:
	guix time-machine -C ./channels-lock.scm -- \
	system disk-image ./ixy.scm

channels-update-lock:
	guix time-machine -C ./channels.scm -- \
	describe -f channels > channels-lock.scm
