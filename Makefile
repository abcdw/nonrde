iso:
	guix time-machine -C ./channels-lock.scm -- system disk-image ./ixy.scm

reconfigure:
	sudo guix time-machine -C ./channels-lock.scm -- system reconfigure ./ixy.scm

reconfigure-local:
	sudo guix time-machine -C ./external-channels.scm -- system -L ../rde reconfigure ./ixy.scm

build:
	guix time-machine -C ./external-channels.scm -- system -L ../rde build ./ixy.scm

update-channels-lock:
	guix time-machine -C ./channels.scm -- describe -f channels > channels-lock.scm
