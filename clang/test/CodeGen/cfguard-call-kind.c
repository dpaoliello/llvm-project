// RUN: %clang_cc1 -emit-llvm %s -o - | FileCheck %s -check-prefix=DEFAULT
// RUN: %clang_cc1 -fwin-cfg-call-kind=default -emit-llvm %s -o - | FileCheck %s -check-prefix=DEFAULT
// RUN: %clang_cc1 -fwin-cfg-call-kind=direct -emit-llvm %s -o - | FileCheck %s -check-prefix=DIRECT
// RUN: %clang_cc1 -fwin-cfg-call-kind=indirect -emit-llvm %s -o - | FileCheck %s -check-prefix=INDIRECT
// RUN: %clang -fwin-cfg-call-kind=direct -S -emit-llvm %s -o - | FileCheck %s -check-prefix=DIRECT

void f(void) {}

// DIRECT: !"cfguard-call-kind", i32 1}
// INDIRECT: !"cfguard-call-kind", i32 2}
// DEFAULT-NOT: "cfguard-call-kind"