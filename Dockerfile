ARG ARCH
FROM ${ARCH}/ubuntu:focal
MAINTAINER yhaenggi <yhaenggi-git-public@darkgamex.ch>

ARG ARCH
ARG VERSION
ARG IMAGE
ENV VERSION=${VERSION}
ENV ARCH=${ARCH}
ENV IMAGE=${IMAGE}

COPY ./qemu-arm /usr/bin/qemu-arm
COPY ./qemu-aarch64 /usr/bin/qemu-aarch64

RUN echo force-unsafe-io | tee /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
RUN apt-get update

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install git build-essential cmake -y

WORKDIR /tmp/
RUN git clone --depth 1 --branch v${VERSION} https://github.com/mumble-voip/mumble ${IMAGE}
WORKDIR /tmp/${IMAGE}/
RUN git submodule update --init

RUN apt-get install -y build-essential cmake pkg-config
RUN apt-get install -y qt5-qmake qttools5-dev qttools5-dev-tools libqt5svg5-dev
RUN apt-get install -y libboost-dev libssl-dev libprotobuf-dev protobuf-compiler libprotoc-dev libcap-dev
RUN apt-get install -y libogg-dev libzeroc-ice-dev libpoco-dev

RUN mkdir build
WORKDIR /tmp/${IMAGE}/build
RUN cmake -Dclient=OFF -Dserver=ON -Dstatic=ON -Dzeroconf=OFF -Ddbus=OFF ..
RUN bash -c "nice -n 20 make -j$(nproc)"

FROM ${ARCH}/ubuntu:focal
ARG IMAGE
ENV IMAGE=${IMAGE}

COPY ./qemu-arm /usr/bin/qemu-arm
COPY ./qemu-aarch64 /usr/bin/qemu-aarch64

WORKDIR /root/

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# dependencies
RUN apt-get update && apt-get install netcat libcap2 libprotobuf17 libzeroc-ice3.7 libqt5core5a libqt5network5 libqt5sql5 libqt5xml5 -y && apt-get clean && rm -Rf /var/cache/apt/ && rm -Rf /var/lib/apt/lists

RUN mkdir -p /home/murmur/.murmur
RUN useradd -M -d /home/murmur -u 911 -U -s /bin/bash murmur
RUN usermod -G users murmur

COPY --from=0 /tmp/${IMAGE}/build/mumble-server /usr/bin/murmurd
COPY --from=0 /tmp/${IMAGE}/build/murmur.ini /home/murmur/.murmur/murmur.ini
RUN sed -i 's/^database=$/database=\/home\/murmur\/.murmur\/murmur.sqlite/' /home/murmur/.murmur/murmur.ini

RUN chown murmur:murmur /home/murmur -R

RUN rm /usr/bin/qemu-arm* /usr/bin/qemu-aarch64*

USER murmur
WORKDIR /home/murmur

EXPOSE 64738/tcp 64738/udp 50051

ENTRYPOINT ["/usr/bin/murmurd"]
CMD ["-v", "-fg", "-ini", "/home/murmur/.murmur/murmur.ini"]
