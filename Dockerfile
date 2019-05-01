FROM alpine:3.9.3
MAINTAINER Art Eschenlauer, esch0041@umn.edu
LABEL reference="'https://wiki.alpinelinux.org/wiki/How_to_get_regular_stuff_working'" motivation="'Create an environment to compile C programs targeting musl- or statically-linked binaries.'"
RUN apk add bash vim
RUN apk add build-base gcc abuild binutils binutils-doc gcc-doc
RUN apk add cmake cmake-doc
RUN apk add ccache ccache-doc
# These failed on alpine:3.9.3
# RUN apk add extra-cmake-modules
# RUN apk add extra-cmake-modules-doc
RUN sed -i -e 's/ssize_t getline/\/\/ ssize_t getline/' /usr/include/stdio.h
COPY Dockerfile /Dockerfile
