// RUN: %clang_cc1 -triple dxil-pc-shadermodel6.3-library -emit-llvm -disable-llvm-passes %s -o - | FileCheck %s

// Make sure global variable for ctors exist for lib profile.
// CHECK:@llvm.global_ctors

RWBuffer<float> Buffer;

[shader("compute")]
[numthreads(1,1,1)]
void FirstEntry() {}

// CHECK: define void @FirstEntry()
// CHECK-NEXT: entry:
// CHECK-NEXT:   call void @_GLOBAL__sub_I_GlobalConstructorLib.hlsl()

[shader("compute")]
[numthreads(1,1,1)]
void SecondEntry() {}

// CHECK: define void @SecondEntry()
// CHECK-NEXT: entry:
// CHECK-NEXT:   call void @_GLOBAL__sub_I_GlobalConstructorLib.hlsl()
// CHECK-NEXT:   call void @"?SecondEntry@@YAXXZ"()
