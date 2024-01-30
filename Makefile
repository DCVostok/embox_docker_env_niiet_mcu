-include user_config.mk
PRJ_DIR?=$(shell pwd)

OPENOCD_TARGET_ARGS?=-f board/vostok_vg015_dev.cfg
OPENOCD?=/usr/local/bin/openocd $(OPENOCD_TARGET_ARGS)
FIRMWARE_FILE?=embox/build/base/bin/embox.bin
ELF_FILE?=embox/build/base/bin/embox
UPLOAD_OFFSET_ADDR?=0x80000000

SERIAL_PORT?=/dev/ttyUSB0
SERIAL_BOUDRATE?=115200

DOCKER_IMAGE_TAG?=vostok_embox_env:1.0
DOCKER_RUN_ARGS?= \
	-v $(PRJ_DIR):/prj \
	-u $(shell id -u):$(shell id -g) \
	-v /dev:/dev \
	-w /prj \
	--rm \
	--privileged

DOCKER_RUN_CMD?=docker run $(DOCKER_RUN_ARGS)


REMOTE_SERVER?=
SSH_ARGS+= -tt
SSH?=ssh $(SSH_ARGS) $(SSH_TARGET)


.PHONY : $(sort $(MAKECMDGOALS))
$(sort $(MAKECMDGOALS)) :
	${DOCKER_RUN_CMD} ${DOCKER_IMAGE_TAG} $(MAKE) -f embox/Makefile $@ EXT_PROJECT_PATH=$(EXT_PROJECT_PATH)

.PHONY:
all:
	${DOCKER_RUN_CMD} ${DOCKER_IMAGE_TAG} $(MAKE) -f embox/Makefile

.PHONY : docker_run
docker_run:
	${DOCKER_RUN_CMD} -it ${DOCKER_IMAGE_TAG}

.PHONY : docker_build
docker_build:
	docker build . \
	-t ${DOCKER_IMAGE_TAG}

.PHONY : upload
upload:all
	${DOCKER_RUN_CMD} ${DOCKER_IMAGE_TAG} \
	$(OPENOCD) \
	-c "init; reset init; flash probe 0; program ${FIRMWARE_FILE} ${UPLOAD_OFFSET_ADDR} verify reset; shutdown;"


.PHONY : debug_server
debug_server:
	${DOCKER_RUN_CMD} \
	-p 5555:5555 \
	${DOCKER_IMAGE_TAG} \
	$(OPENOCD) \
	-c 'gdb_port 5555;bindto 0.0.0.0'

.PHONY : monitor serial_monitor
monitor serial_monitor:
	${DOCKER_RUN_CMD} \
	-it \
	${DOCKER_IMAGE_TAG} \
	picocom $(SERIAL_PORT) -b $(SERIAL_BOUDRATE) --omap delbs

# BEGIN Remote targets -----------------------------------------------

.PHONY : remote_debug_server
remote_debug_server:
	${SSH} "\
	$(OPENOCD) \
	-c 'gdb_port 5555;bindto 0.0.0.0'"

.PHONY : remote_shutdown_debug_server
remote_shutdown_debug_server:
	${DOCKER_RUN_CMD} ${DOCKER_IMAGE_TAG} \
	gdb-multiarch -ex "target extended-remote ${REMOTE_SERVER}" -ex "mon shutdown" -ex "detach" -ex "exit" ${ELF_FILE}

.PHONY : remote_upload
remote_upload:
	${DOCKER_RUN_CMD} ${DOCKER_IMAGE_TAG} \
	riscv-none-elf-gdb -ex "target extended-remote ${REMOTE_SERVER}" -ex "load" -ex "mon reset" -ex "detach" -ex "exit" ${ELF_FILE}

.PHONY : remote_gdb
remote_gdb:
	${DOCKER_RUN_CMD} \
	-it \
	${DOCKER_IMAGE_TAG} \
	riscv-none-elf-gdb -ex "target extended-remote ${REMOTE_SERVER}" -ex "load" -ex "mon reset" ${ELF_FILE}

.PHONY : remote_monitor remote_serial_monitor
remote_monitor remote_serial_monitor:
	${SSH} "picocom $(SERIAL_PORT) -b $(SERIAL_BOUDRATE) --omap delbs"

# END Remote targets -----------------------------------------------

.PHONY : compile_commands
compile_commands:
	$(MAKE) clean && \
	${DOCKER_RUN_CMD} \
	${DOCKER_IMAGE_TAG} \
	bear -- $(MAKE) -j -f embox/Makefile | tee header_override.json && \
	sed -i 's/--debug-prefix-map/-fdebug-prefix-map/' compile_commands.json && \
	sed -i 's,/prj,'"${PRJ_DIR}"',' compile_commands.json && \
	sed -i -n '/^cp -r -T/p' header_override.json && \
	sed -i -r 's/^cp -r -T ([^ ]+) (.+)/    "\2": "\1",/p' header_override.json && \
	sed -i '1s/^/{\n/' header_override.json && \
	sed -i '$$s/,$$/\n}/' header_override.json && \
	sed -i 's,/prj/,,' header_override.json && \
	sed -i 's,//,/,' header_override.json && \
	sed -i 's,"ext_project/,"project/,' header_override.json && \
	sed -i 's,"src/,"embox/src/,' header_override.json



.PHONY : size_elf
size_elf:all
	${DOCKER_RUN_CMD} \
	${DOCKER_IMAGE_TAG} \
	elf-size-analyze -t arm-none-eabi- embox/build/base/bin/embox -W --rom  > embox_rom_size.html

	${DOCKER_RUN_CMD} \
	${DOCKER_IMAGE_TAG} \
	elf-size-analyze -t arm-none-eabi- embox/build/base/bin/embox -W --ram  > embox_ram_size.html
