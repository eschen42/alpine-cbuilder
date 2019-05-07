[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.2656635.svg)](https://doi.org/10.5281/zenodo.2656635)
[Docker Repository](https://hub.docker.com/r/eschen42/alpine-cbuilder)

# A build environment for musl to target Alpine Linux

## Binaries linked against `glibc` do not run on Alpine

For the `libc` C library, Alpine Linux uses `musl` [https://www.musl-libc.org/](https://www.musl-libc.org/) rather than `uclibc` or `glibc` when loading its non-statically linked binaries.
So, the solution to building executables to run on Alpine is either to statically link them or to link them against `musl`.

## A Docker image for producing binaries to run on Alpine

The two options for linking against `musl` are to compile in a Docker container or to cross-compile with `musl-gcc` (see [https://scripter.co/nim-deploying-static-binaries/#installing-musl](https://scripter.co/nim-deploying-static-binaries/#installing-musl) for a concise summary of how to cross compile).

I created this build environment in Docker to support the non-cross-compiling alternative and so that I can compile targeting `musl` (or static) anywhere, as long as either I have Docker and root access or I can (rootlessly) run usernetes [https://github.com/rootless-containers/usernetes](https://github.com/rootless-containers/usernetes).  An arguably less involved approach might have been to create a Docker image supporting `musl-gcc`.

This Docker image implements the advice at [https://wiki.alpinelinux.org/wiki/How\_to\_get\_regular\_stuff\_working](https://wiki.alpinelinux.org/wiki/How_to_get_regular_stuff_working)

## Why use `musl` rather than `glibc`

Evidently, statically linking libaries against `glibc` does not result in complete static linking: see [https://github.com/rust-lang/cargo/issues/2968#issuecomment-238196762](https://github.com/rust-lang/cargo/issues/2968#issuecomment-238196762) and it runs up against licensing issues [https://lwn.net/Articles/117972/](https://lwn.net/Articles/117972/).  By contrast, `musl` carries the non-restrictive MIT Licence, and it makes completely static links.

## Why hack `stdio.h` in the Dockerfile?

When I tried to compile `cvs` (first use case below) I got a duplicate definition of `getline` (because of fortify).  I chose to retain the fortify version and discard the base version:

```bash
RUN sed -i -e 's/ssize_t getline/\/\/ ssize_t getline/' /usr/include/stdio.h
```

# Use cases

## CVS executable, independent of `glibc`

I created this image because I needed to compile `cvs` to run on Alpine.  Here is a summary of the steps that I took.

```bash
# build the build-image
mkdir ~/src/alpine-cbuilder
cd ~/src/alpine-cbuilder
gvim Dockerfile
docker build -t alpine-cbuilder .
# get the source code for cvs
mkdir ~/src/alpine-cvs
cd ~/src/alpine-cvs
wget https://ftp.gnu.org/non-gnu/cvs/source/stable/1.11.23/cvs-1.11.23.tar.gz
tar xvzf cvs-1.11.23.tar.gz
# enter the build system
docker run --rm -ti -v `pwd`/cvs-1.11.23:/src alpine-cbuilder bash
```

Within the `alpine-cbuilder` container:

```bash
cd src
# link statically - without this it would link to musl, resulting in a binary 25% smaller
export LDFLAGS='--static'
make distclean
./configure
make
exit
```

At this point, there is a statically linked cvs binary at `~/src/alpine-cvs/cvs-1.11.23/src/cvs`.

## Statically linked `busybox`

Within the `alpine-cbuilder` container:

```bash
wget https://busybox.net/downloads/busybox-1.30.1.tar.bz2
bzip2 -d busybox-1.30.1.tar.bz2
tar xf busybox-1.30.1.tar
cd busybox-1.30.1.tar
make defconfig
export LDFLAGS="--static"
make
```
