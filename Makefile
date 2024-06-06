VERSION=latest
GUIX_PROFILE=target/profiles/guix
GUIX=./pre-inst-env ${GUIX_PROFILE}/bin/guix

SRC_DIR=./src
CONFIGS=${SRC_DIR}/configs.scm
PULL_EXTRA_OPTIONS=
# --allow-downgrades
ROOT_MOUNT_POINT=/mnt

include ../rde/examples/profiles.mk

authorize-nonguix:
	sudo guix archive --authorize < signing-key.pub

ixy/system/build: guix
	RDE_TARGET=ixy-system ${GUIX} \
	system \
        --substitute-urls="https://substitutes.nonguix.org https://ci.guix.gnu.org https://bordeaux.guix.gnu.org" \
	build ${CONFIGS}

ixy/system/reconfigure: guix
	RDE_TARGET=ixy-system sudo ${GUIX} system \
	reconfigure ${CONFIGS} # --allow-downgrades

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

release/nonrde-live-x86_64: target/release # target/nonrde-live.iso
	cp -df target/nonrde-live.iso target/release/nonrde-live-${VERSION}-x86_64.iso
	gpg -ab target/release/nonrde-live-${VERSION}-x86_64.iso

clean-target:
	rm -rf ./target
