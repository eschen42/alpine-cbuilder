FROM alpine:3.10.1
LABEL maintainer="'Art Eschenlauer, esch0041@umn.edu'"
LABEL reference="'https://wiki.alpinelinux.org/wiki/How_to_get_regular_stuff_working'" motivation="'Create an environment to compile C programs targeting musl- or statically-linked binaries.'"
RUN apk add bash vim
RUN apk add build-base gcc abuild binutils binutils-doc gcc-doc
RUN apk add cmake cmake-doc
RUN apk add ccache ccache-doc
# These failed on alpine:3.9.3
# RUN apk add extra-cmake-modules
# RUN apk add extra-cmake-modules-doc
# 'getline' in stdio.h collides with 'getline' in the fortify headers
RUN sed -i -e 's/ssize_t getline/\/\/ ssize_t getline/' /usr/include/stdio.h
# Linux headers are necessary to compile and link static busybox
RUN apk add linux-headers
# Needed to view man pages
RUN apk add man
# Files needed to build man pages
RUN apk add perl
RUN apk add groff
RUN apk add groff-doc
# Uncomment if you want git installed
# RUN apk add git
# install md2roff: 
LABEL md2roff_usage="'md2roff md2roff.md > md2roff.1; gzip -f md2roff.1; install -m 0644 md2roff.1.gz /usr/local/man/man1'"
RUN mkdir -p /usr/local/man/man1 \
 && mkdir /src \
 && cd src \
 && wget https://github.com/nereusx/md2roff/archive/master.zip \
 && unzip master.zip \
 && rm master.zip \
 && cd md2roff-master \
 && bash -c "export LDFLAGS='--static'; make && make install" \
 && cd .. && rm -rf md2roff-master
COPY Dockerfile /Dockerfile
