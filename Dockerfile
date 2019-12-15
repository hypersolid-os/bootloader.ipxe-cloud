FROM debian:buster as build

ENV DEBIAN_FRONTEND=noninteractive

# working dir
WORKDIR /opt

# install dependencies
RUN set -xe \
    && apt-get update \
    && apt-get -y --no-install-recommends \
        install extlinux gdisk

# copy files
COPY entrypoint.sh /entrypoint.sh
COPY extlinux/ /opt
COPY ipxe/ /opt

# start bash
ENTRYPOINT [ "/bin/bash" , "-c"]
CMD [ "/entrypoint.sh" ]