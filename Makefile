VERSION=latest
GUIX_PROFILE=target/profiles/guix
GUIX=./pre-inst-env ${GUIX_PROFILE}/bin/guix

SRC_DIR=./src
CONFIGS=${SRC_DIR}/configs.scm
PULL_EXTRA_OPTIONS=
# --allow-downgrades
ROOT_MOUNT_POINT=/mnt

ixy/system/reconfigure: guix
	RDE_TARGET=ixy-system ${GUIX} system \
	reconfigure ${CONFIGS}

cow-store:
	sudo herd start cow-store ${ROOT_MOUNT_POINT}

ixy/system/init: guix
	RDE_TARGET=ixy-system ${GUIX} system \
	init ${CONFIGS} ${ROOT_MOUNT_POINT}

target:
	mkdir -p target

target/nonrde-live.iso: guix target
	RDE_TARGET=live-system ${GUIX} system image --image-type=iso9660 \
	${CONFIGS} -r target/nonrde-live-tmp.iso
	mv -f target/nonrde-live-tmp.iso target/nonrde-live.iso

target/release:
	mkdir -p target/release

release/nonrde-live-x86_64: target/nonrde-live.iso target/release
	cp -df $< target/release/nonrde-live-${VERSION}-x86_64.iso
	gpg -ab target/release/nonrde-live-${VERSION}-x86_64.iso


#
# Profiles
#

guix: target/profiles/guix.lock

target/profiles:
	mkdir -p target/profiles

target/profiles/guix.lock: rde/channels-lock.scm
	make target/profiles/guix

target/profiles/guix: target/profiles rde/channels-lock.scm
	guix pull -C rde/channels-lock.scm -p ${GUIX_PROFILE} \
	${PULL_EXTRA_OPTIONS}

target/profiles/guix-local: target/profiles rde/channels-lock-local.scm
	guix pull -C rde/channels-lock-local.scm -p ${GUIX_PROFILE} \
	${PULL_EXTRA_OPTIONS}

rde/channels-lock.scm: rde/channels.scm
	echo -e "(use-modules (guix channels))\n" > ./rde/channels-lock-tmp.scm
	guix time-machine -C ./rde/channels.scm -- \
	describe -f channels >> ./rde/channels-lock-tmp.scm
	mv ./rde/channels-lock-tmp.scm ./rde/channels-lock.scm

rde/channels-lock-local.scm: rde/channels-local.scm
	echo -e "(use-modules (guix channels))\n" > ./rde/channels-lock-tmp.scm
	guix time-machine -C ./rde/channels-local.scm -- \
	describe -f channels >> ./rde/channels-lock-tmp.scm
	mv ./rde/channels-lock-tmp.scm ./rde/channels-lock-local.scm


clean-target:
	rm -rf ./target
