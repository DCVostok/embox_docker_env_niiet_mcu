
FROM ubuntu:23.04

# Container utils
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
        git \
        sudo \
		iptables \
		openssh-server \
		iproute2 \
		bzip2 \
		unzip \
		xz-utils \
		python3 \
        python-is-python3 \
		python3-pip\
		pipx\
		libusb-1.0-0-dev \
		libncurses5 \
		libncursesw5 \
		curl \
		make \
		patch \
		cpio \
		gcc-multilib \
		g++-multilib \
		gdb \
		qemu-system \
		ruby \
		bison \
		flex \
		bc \
		autoconf \
		pkg-config \
		mtd-utils \
		ntfs-3g \
		autotools-dev \
		automake \
		xutils-dev \
		picocom \
		libtool \
		npm \
		gdb-multiarch \
		bear && \
		apt-get clean && \
		rm -rf /var/lib/apt /var/cache/apt

ARG ARM_TOOLCHAIN_VERSION=13.2.1-1.1.1
ARG RISCV_TOOLCHAIN_VERSION=13.2.0-2.1
ARG OPENOCD_VERSION=7352db9

RUN npm install --global xpm@0.18.0
RUN xpm install --global @xpack-dev-tools/arm-none-eabi-gcc@${ARM_TOOLCHAIN_VERSION}
RUN xpm install --global @xpack-dev-tools/riscv-none-elf-gcc@${RISCV_TOOLCHAIN_VERSION}

RUN  rm -rf ~/.cache 

RUN git clone https://github.com/DCVostok/openocd-k1921vk.git && \
    cd openocd-k1921vk && git checkout ${OPENOCD_VERSION} && \
    ./bootstrap && ./configure --enable-dummy && make -j 4 && make install && \
    cd ../ && rm -rf openocd-k1921vk

ENV PATH=$PATH:\
/root/.local/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/${RISCV_TOOLCHAIN_VERSION}/.content/bin/:\
/root/.local/xPacks/@xpack-dev-tools/arm-none-eabi-gcc/${ARM_TOOLCHAIN_VERSION}/.content/bin/
EXPOSE 55555

RUN  python -m pip install elf-size-analyze --break-system-packages
