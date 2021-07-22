# build with:
#   docker build --build-arg "MAINTAINER=My Name <My@Email>" -t ooopy .
#
# ooo_mailmerge usage example:
#   docker run -it --rm --net none -v `pwd`:/tmp:ro ooopy ooo_mailmerge /tmp/in.odt /tmp/in.csv >out.odt
#   description:
#     The input file folder is mapped read-only into the container to /tmp
#     Output file is written to stdout, to remove the hassle of writing files and
#     mapping of UIDs.
#     The container is started without networking because it is not needed.

###
## BUILD
###

ARG MAINTAINER

FROM debian:buster
ENV VERSION 1.11
LABEL maintainer=$MAINTAINER

# install build dependencies
RUN set -ex \
    && apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
        python-stdeb \
        fakeroot \
        dh-python \
        python-all \
        build-essential:native \
        git

COPY . /ooopy

RUN set -ex \
    && cd /ooopy \
    && echo "${VERSION}~$(git rev-parse --short HEAD)" >/VERSION \
    && echo "VERSION = \"${VERSION}~$(git rev-parse --short HEAD)\"" >ooopy/Version.py \
    && python setup.py --command-packages=stdeb.command sdist_dsc --maintainer "$MAINTAINER" bdist_deb


###
## RUNTIME
###

FROM debian:10.10-slim
LABEL maintainer=$MAINTAINER

# install runtime dependencies
RUN set -ex \
    && apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
        python2.7-minimal \
        python

COPY --from=0 /VERSION /
COPY --from=0 /ooopy/deb_dist/python-ooopy_*_all.deb /

RUN set -ex \
    && dpkg -i /*.deb

USER 999:999
