//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include <clc/opencl/relational/isless.h>
#include <clc/relational/clc_isless.h>

#define FUNCTION isless
#define __CLC_BODY "binary_def.inc"

#include <clc/math/gentype.inc>
