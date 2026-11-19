#!/bin/sh
set -eu

if [ ! -f packaging/scripts/release-size-profile ]; then
  echo "Run this script from the root of an aria2-next checkout" >&2
  exit 2
fi

: "${ALPINE_LDFLAGS:=-static}"
: "${ARIA2_RELEASE_LTO:=ON}"
: "${CMAKE_POLICY_VERSION_MINIMUM:=3.5}"
export CMAKE_POLICY_VERSION_MINIMUM

export PREFIX="${PREFIX:-$PWD/build/release/dependencies}"
export ARIA2_BUILD_PROFILE=release

. packaging/scripts/release-size-profile linux

build_dir=build/release
jobs=$(nproc 2>/dev/null || echo 2)

cmake -S . -B "$build_dir" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  "-DCMAKE_C_FLAGS=$RELEASE_CFLAGS" \
  "-DCMAKE_CXX_FLAGS=$RELEASE_CXXFLAGS" \
  "-DCMAKE_EXE_LINKER_FLAGS=$RELEASE_LDFLAGS $ALPINE_LDFLAGS" \
  -DARIA2_RELEASE_SIZE_OPTIMIZED=ON \
  "-DARIA2_RELEASE_LTO=$ARIA2_RELEASE_LTO" \
  "-DCMAKE_POLICY_VERSION_MINIMUM=$CMAKE_POLICY_VERSION_MINIMUM" \
  -DBUILD_TESTING=OFF \
  -DCMAKE_SKIP_RPATH=ON

cmake --build "$build_dir" --target aria2_project -j"$jobs"

binary="$build_dir/aria2-next"
strip "$binary"

packaging/scripts/check-runtime-deps linux "$binary"
"$binary" --version
