#!/bin/env sh
set -eu
# 'getline' in stdio.h collides with 'getline' in the fortify headers
sed -i -e 's/^[ ]*ssize_t getline/\/\/ ssize_t getline/' /usr/include/stdio.h
# Linux headers are necessary to compile and link static busybox
# install md2roff:
#LABEL md2roff_usage="md2roff md2roff.md > md2roff.1; gzip -f md2roff.1; install -m 0644 md2roff.1.gz /usr/local/man/man1"
mkdir -p /usr/local/man/man1
mkdir -p /src
if [ -d /src ]; then
  cd /src
  if [ ! -e master.zip ]; then \
        wget https://github.com/nereusx/md2roff/archive/master.zip \
        && unzip master.zip \
        && rm master.zip; \
  fi
  cd md2roff-master \
    && sh -c "export LDFLAGS='--static'; make && make install" \
    && md2roff md2roff.md > md2roff.1 \
    && gzip -f md2roff.1 \
    && install -m 0644 md2roff.1.gz /usr/local/man/man1 \
    && cd .. \
    && rm -rf md2roff-master
fi
