//===-- Implementation of fclose ------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "src/stdio/fclose.h"
#include "src/__support/File/file.h"

#include "hdr/types/FILE.h"
#include "src/__support/libc_errno.h"
#include "src/__support/macros/config.h"

namespace LIBC_NAMESPACE_DECL {

LLVM_LIBC_FUNCTION(int, fclose, (::FILE * stream)) {
  int result = reinterpret_cast<LIBC_NAMESPACE::File *>(stream)->close();
  if (result != 0) {
    libc_errno = result;
    return EOF;
  }
  return 0;
}

} // namespace LIBC_NAMESPACE_DECL
