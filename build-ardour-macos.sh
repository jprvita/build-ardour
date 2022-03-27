#!/bin/bash -ex

# Server to use when cloning ardour repositories
GIT_SERVER=git://git.ardour.org/ardour


if [[ ${#} -gt 1 ]] ; then
  echo "usage: $0 <version>"
  exit 1
elif [[ ${#} -eq 1 ]] ; then
  ARDOUR_VERSION="${1}"
fi

WORKDIR=$(mktemp -d -t $(basename $0))
SRC_CACHE=/var/tmp/src_cache/

# Fetch and build dependencies
BUILD_TOOLS_SRC_DIR=${WORKDIR}/ardour-build-tools
BUILD_TOOLS_REPO=${GIT_SERVER}/ardour-build-tools.git
git clone ${BUILD_TOOLS_REPO} ${BUILD_TOOLS_SRC_DIR}
mkdir -p ${BUILD_TOOLS_SRC_DIR}/build
pushd ${BUILD_TOOLS_SRC_DIR}/build
${BUILD_TOOLS_SRC_DIR}/build-stack
popd
rm -rf ${BUILD_TOOLS_SRC_DIR}

# Fetch, build and package Ardour
STACK_PREFIX=$HOME/gtk/inst
ARDOUR_SRC_DIR=${WORKDIR}/ardour
ARDOUR_REPO=${GIT_SERVER}/ardour.git
git clone ${ARDOUR_REPO} ${ARDOUR_SRC_DIR}
pushd ${ARDOUR_SRC_DIR}
if [[ -z ${ARDOUR_VERSION} ]] ; then
  ARDOUR_VERSION=$(git describe --abbrev=0)
fi
git checkout ${ARDOUR_VERSION}
touch ${ARDOUR_SRC_DIR}/libs/ardour/revision.cc
./waf configure --optimize \
  PKG_CONFIG_PATH=${STACK_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH \
  PATH=${STACK_PREFIX}/bin:$PATH
./waf
pushd tools/osx_packaging
./osx_build --public
popd
popd
mv ${ARDOUR_SRC_DIR}/tools/osx_packaging/Ardour-${ARDOUR_VERSION}.0.dmg .
rm -rf ${ARDOUR_SRC_DIR}
rm -rf ${STACK_PREFIX}
rm -rf ${WORKDIR}
echo "Ardour package built at $(ls Ardour-${ARDOUR_VERSION}.0.dmg)"
echo "You may want to remove the dependencies source tarball cache at ${SRC_CACHE}"
