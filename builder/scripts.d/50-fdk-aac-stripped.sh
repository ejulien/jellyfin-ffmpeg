#!/bin/bash

SCRIPT_REPO="https://gitlab.freedesktop.org/wtaymans/fdk-aac-stripped.git"
SCRIPT_COMMIT="529b87452cd33d45e1d0a5066d20b64f10b38845"

ffbuild_enabled() {
    # Off for Alumira: Fraunhofer's licence is not compatible with the GPL
    # these builds are under (Alumira encodes with FFmpeg's own AAC)
    return -1
}

ffbuild_dockerbuild() {
    git-mini-clone "$SCRIPT_REPO" "$SCRIPT_COMMIT" fdk
    cd fdk

    ./autogen.sh

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-shared
        --enable-static
        --with-pic
        --disable-example
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
        )
    elif [[ $TARGET == mac* ]]; then
        :
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install
}

ffbuild_configure() {
    echo --enable-libfdk-aac
}

ffbuild_unconfigure() {
    echo --disable-libfdk-aac
}
