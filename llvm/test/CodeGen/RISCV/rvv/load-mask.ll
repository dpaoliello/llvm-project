; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple riscv32 -mattr=+v %s -o - \
; RUN:     -verify-machineinstrs | FileCheck %s
; RUN: llc -mtriple riscv64 -mattr=+v %s -o - \
; RUN:     -verify-machineinstrs | FileCheck %s

define void @test_load_mask_64(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_64:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, m8, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 64 x i1>, ptr %pa
  store <vscale x 64 x i1> %a, ptr %pb
  ret void
}

define void @test_load_mask_32(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, m4, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 32 x i1>, ptr %pa
  store <vscale x 32 x i1> %a, ptr %pb
  ret void
}

define void @test_load_mask_16(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, m2, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 16 x i1>, ptr %pa
  store <vscale x 16 x i1> %a, ptr %pb
  ret void
}

define void @test_load_mask_8(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, m1, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 8 x i1>, ptr %pa
  store <vscale x 8 x i1> %a, ptr %pb
  ret void
}

define void @test_load_mask_4(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_4:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, mf2, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 4 x i1>, ptr %pa
  store <vscale x 4 x i1> %a, ptr %pb
  ret void
}

define void @test_load_mask_2(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_2:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, mf4, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 2 x i1>, ptr %pa
  store <vscale x 2 x i1> %a, ptr %pb
  ret void
}

define void @test_load_mask_1(ptr %pa, ptr %pb) {
; CHECK-LABEL: test_load_mask_1:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a2, zero, e8, mf8, ta, ma
; CHECK-NEXT:    vlm.v v8, (a0)
; CHECK-NEXT:    vsm.v v8, (a1)
; CHECK-NEXT:    ret
  %a = load <vscale x 1 x i1>, ptr %pa
  store <vscale x 1 x i1> %a, ptr %pb
  ret void
}
