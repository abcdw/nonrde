VERSION=0.5.0
CHANNELS_FILE=./env/guix/nonrde/env/guix/channels.scm

GUIX_ENV_LOAD_PATH=-L ./env/guix -L ../rde/examples/env/guix
DEV_ENV_LOAD_PATH=-L ./env/guix -L ./env/dev \
-L ../rde/examples/env/guix -L ../rde/examples/env/dev
GUIXTM=guix time-machine ${GUIX_ENV_LOAD_PATH} -C ${CHANNELS_FILE}
GUIX=$(GUIXTM) --

ALL_SRC_LOAD_PATH=${GUIX_ENV_LOAD_PATH} \
-L ./src -L ../rde/examples/src -L ../rde/src

SRC_DIR=./src
CONFIGS=${SRC_DIR}/configs.scm
PULL_EXTRA_OPTIONS=
# --allow-downgrades
ROOT_MOUNT_POINT=/mnt

ares:
	${GUIX} shell ${DEV_ENV_LOAD_PATH} guile-next guile-ares-rs \
	-e '(@ (nonrde env dev packages) guix-package)' \
	-e '(@ (nonrde env dev packages) channels-package)' \
	-- guile \
	${ALL_SRC_LOAD_PATH} \
	-L /data/abcdw/work/abcdw/guile-ares-rs/src/guile \
	-c \
"(begin (use-modules (guix gexp)) #;(load gexp reader macro globally) \
((@ (ares server) run-nrepl-server)))"

authorize-nonguix:
	sudo guix archive --authorize < signing-key.pub

describe:
	${GUIX} describe

ixy/system/build:
	RDE_TARGET=ixy-system ${GUIX} \
	system ${ALL_SRC_LOAD_PATH} \
        --substitute-urls="https://substitutes.nonguix.org https://ci.guix.gnu.org https://bordeaux.guix.gnu.org" \
	build ${CONFIGS}

ixy/system/reconfigure:
	RDE_TARGET=ixy-system sudo -E ${GUIX} system \
	reconfigure ${ALL_SRC_LOAD_PATH} ${CONFIGS} # --allow-downgrades

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
