#!/bin/bash

set -e

. ../lib/lib.sh $@
. ../lib/msg.sh $0

target=$PREFIX/bin/vim
pkg=vim.tar.gz

if test -z $forceInstall
then
    test -f $target && $target --version && exit 0
fi

cd $TMP
#download "https://github.com/vim/vim/archive/v7.4.2367.tar.gz" $pkg
downloadByGit "https://gitee.com/yyzybb537/vim-tgz.git" vimgit
cd vimgit
tar zxf $pkg
dir=`tar tf $pkg | head -1`
cd $dir
./configure --with-features=huge --enable-multibyte \
    --enable-pythoninterp=yes --enable-rubyinterp=yes \
    --enable-luainterp=yes --enable-perlinterp=yes \
    --enable-gui=gtk2 \
    --with-tlib=ncurses \
    --enable-cscope \
    --with-python-config-dir=$PREFIX/lib/python2.7/config \
    --prefix=$PREFIX
make $MAKEFLAGS
make install
