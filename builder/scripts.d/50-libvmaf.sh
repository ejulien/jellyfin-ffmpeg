#!/bin/bash

# Alumira: VMAF for the quality measurements of encodes (libvmaf filter)
SCRIPT_REPO="https://github.com/Netflix/vmaf.git"
SCRIPT_COMMIT="v3.2.1"

ffbuild_enabled() {
    [[ $TARGET == win32 ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    git clone --depth 1 --branch "$SCRIPT_COMMIT" "$SCRIPT_REPO" vmaf
    cd vmaf/libvmaf

    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        -Denable_tests=false
        -Denable_docs=false
        -Dbuilt_in_models=true
        -Denable_float=true
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    elif [[ $TARGET == mac* ]]; then
        if [ "$MACOS_BUILDER_CPU_ARCH" = "arm64" ] && [ "$TARGET" = "mac64" ]; then
            myconf+=(
                --cross-file="$BUILDER_ROOT"/images/macos/cross/cross-x86_64.txt
            )
        fi
    else
        echo "Unknown target"
        return -1
    fi

    meson "${myconf[@]}" ..
    ninja -j$(nproc)
    ninja install

    # its SVM part is C++: a static libvmaf links its runtime too
    local cxx=-lstdc++
    [[ $TARGET == mac* ]] && cxx=-lc++
    local pc="$FFBUILD_PREFIX"/lib/pkgconfig/libvmaf.pc
    if grep -q '^Libs.private:' "$pc"; then
        sed -i.bak "s/^Libs.private:.*/& $cxx/" "$pc"
    else
        echo "Libs.private: $cxx" >> "$pc"
    fi
}

ffbuild_configure() {
    echo --enable-libvmaf
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
