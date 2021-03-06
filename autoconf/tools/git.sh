#!/bin/bash

set -e

. ../lib/lib.sh $@
. ../lib/msg.sh $0

target=$PREFIX/bin/git
pkg=git.tar.gz

if test -z $forceInstall
then
    test -f $target && $target --version && exit 0 || echo -n
    git --version && exit 0 || echo -n
fi

cd $TMP
download "https://www.kernel.org/pub/software/scm/git/git-2.12.2.tar.gz" $pkg
tar zxf $pkg
dir=`tar tf $pkg | head -1`
cd $dir
./configure --prefix=$PREFIX
make $MAKEFLAGS
make install
