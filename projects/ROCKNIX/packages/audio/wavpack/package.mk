# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

. ${ROOT}/packages/audio/wavpack/package.mk

PKG_CMAKE_OPTS_TARGET+=" -DBUILD_SHARED_LIBS=ON"
