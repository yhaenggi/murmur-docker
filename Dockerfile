ARG ARCH
FROM ${ARCH}/ubuntu:bionic
MAINTAINER yhaenggi <yhaenggi-git-public@darkgamex.ch>

ARG ARCH
ARG VERSION
ARG IMAGE
ENV VERSION=${VERSION}
ENV ARCH=${ARCH}
ENV IMAGE=${IMAGE}

COPY ./qemu-x86_64-static /usr/bin/qemu-x86_64-static
COPY ./qemu-arm-static /usr/bin/qemu-arm-static
COPY ./qemu-aarch64-static /usr/bin/qemu-aarch64-static

RUN echo force-unsafe-io | tee /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
RUN apt-get update

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive
#install tzdata package
RUN apt-get install tzdata -y
# set your timezone
RUN ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get install software-properties-common -y
RUN add-apt-repository universe
RUN add-apt-repository multiverse


# prepare build
RUN add-apt-repository ppa:mumble/release -y
RUN sed 's/# deb-src/deb-src/g' -i /etc/apt/sources.list
RUN sed 's/# deb-src/deb-src/g' -i /etc/apt/sources.list.d/*mumble*.list
RUN apt-get update

RUN apt-get build-dep mumble-server -y
RUN apt-get install git debhelper fakeroot devscripts -y
RUN apt-get install build-essential -y

WORKDIR /tmp/
RUN git clone --depth 1 --branch ${VERSION} https://github.com/mumble-voip/mumble ${IMAGE}
WORKDIR /tmp/${IMAGE}/

RUN apt-get install libgrpc++-dev protobuf-compiler protobuf-compiler-grpc libprotoc-dev libprotobuf-dev -y

RUN qmake -recursive main.pro CONFIG+="no-client grpc"
RUN bash -c "nice -n 20 make -j$(nproc) release"

RUN rm /usr/bin/qemu-x86_64-static /usr/bin/qemu-arm-static /usr/bin/qemu-aarch64-static

FROM ${ARCH}/ubuntu:bionic
ARG IMAGE
ENV IMAGE=${IMAGE}

COPY ./qemu-x86_64-static /usr/bin/qemu-x86_64-static
COPY ./qemu-arm-static /usr/bin/qemu-arm-static
COPY ./qemu-aarch64-static /usr/bin/qemu-aarch64-static

WORKDIR /root/

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# dependencies
RUN apt-get update && apt-get install netcat tzdata libcap2 libzeroc-ice3.7 libprotobuf10 libgrpc3 libgrpc++1 libavahi-compat-libdnssd1 libqt5core5a libqt5network5 libqt5sql5 libqt5xml5 libqt5dbus5 -y && apt-get clean && rm -Rf /var/cache/apt/ && rm -Rf /var/lib/apt/lists

# set your timezone
RUN ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN mkdir -p /home/murmur/.murmur
RUN useradd -M -d /home/murmur -u 911 -U -s /bin/bash murmur
RUN usermod -G users murmur

COPY --from=0 /tmp/${IMAGE}/release/murmurd /usr/bin/murmurd
COPY --from=0 /tmp/${IMAGE}/scripts/murmur.ini /home/murmur/.murmur/murmur.ini
RUN sed -i 's/^database=$/database=\/home\/murmur\/.murmur\/murmur.sqlite/' /home/murmur/.murmur/murmur.ini

RUN chown murmur:murmur /home/murmur -R

RUN rm /usr/bin/qemu-x86_64-static /usr/bin/qemu-arm-static /usr/bin/qemu-aarch64-static

USER murmur
WORKDIR /home/murmur

EXPOSE 64738/tcp 64738/udp 50051

ENTRYPOINT ["/usr/bin/murmurd"]
CMD ["-v", "-fg", "-ini", "/home/murmur/.murmur/murmur.ini"]
