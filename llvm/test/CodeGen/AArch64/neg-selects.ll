; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=aarch64-none-elf < %s | FileCheck %s --check-prefixes=CHECK,CHECK-SD
; RUN: llc -mtriple=aarch64-none-elf -global-isel < %s | FileCheck %s --check-prefixes=CHECK,CHECK-GI

define i32 @neg_select_neg(i32 %a, i32 %b, i1 %bb) {
; CHECK-SD-LABEL: neg_select_neg:
; CHECK-SD:       // %bb.0:
; CHECK-SD-NEXT:    tst w2, #0x1
; CHECK-SD-NEXT:    csel w0, w0, w1, ne
; CHECK-SD-NEXT:    ret
;
; CHECK-GI-LABEL: neg_select_neg:
; CHECK-GI:       // %bb.0:
; CHECK-GI-NEXT:    and w8, w2, #0x1
; CHECK-GI-NEXT:    neg w9, w0
; CHECK-GI-NEXT:    tst w8, #0x1
; CHECK-GI-NEXT:    csneg w8, w9, w1, ne
; CHECK-GI-NEXT:    neg w0, w8
; CHECK-GI-NEXT:    ret
  %nega = sub i32 0, %a
  %negb = sub i32 0, %b
  %sel = select i1 %bb, i32 %nega, i32 %negb
  %res = sub i32 0, %sel
  ret i32 %res
}

define i32 @negneg_select_nega(i32 %a, i32 %b, i1 %bb) {
; CHECK-SD-LABEL: negneg_select_nega:
; CHECK-SD:       // %bb.0:
; CHECK-SD-NEXT:    tst w2, #0x1
; CHECK-SD-NEXT:    csneg w0, w1, w0, eq
; CHECK-SD-NEXT:    ret
;
; CHECK-GI-LABEL: negneg_select_nega:
; CHECK-GI:       // %bb.0:
; CHECK-GI-NEXT:    and w8, w2, #0x1
; CHECK-GI-NEXT:    tst w8, #0x1
; CHECK-GI-NEXT:    csneg w8, w1, w0, eq
; CHECK-GI-NEXT:    neg w8, w8
; CHECK-GI-NEXT:    neg w0, w8
; CHECK-GI-NEXT:    ret
  %nega = sub i32 0, %a
  %sel = select i1 %bb, i32 %nega, i32 %b
  %nsel = sub i32 0, %sel
  %res = sub i32 0, %nsel
  ret i32 %res
}

define i32 @neg_select_nega(i32 %a, i32 %b, i1 %bb) {
; CHECK-SD-LABEL: neg_select_nega:
; CHECK-SD:       // %bb.0:
; CHECK-SD-NEXT:    tst w2, #0x1
; CHECK-SD-NEXT:    csneg w0, w0, w1, ne
; CHECK-SD-NEXT:    ret
;
; CHECK-GI-LABEL: neg_select_nega:
; CHECK-GI:       // %bb.0:
; CHECK-GI-NEXT:    and w8, w2, #0x1
; CHECK-GI-NEXT:    tst w8, #0x1
; CHECK-GI-NEXT:    csneg w8, w1, w0, eq
; CHECK-GI-NEXT:    neg w0, w8
; CHECK-GI-NEXT:    ret
  %nega = sub i32 0, %a
  %sel = select i1 %bb, i32 %nega, i32 %b
  %res = sub i32 0, %sel
  ret i32 %res
}

define i32 @neg_select_negb(i32 %a, i32 %b, i1 %bb) {
; CHECK-SD-LABEL: neg_select_negb:
; CHECK-SD:       // %bb.0:
; CHECK-SD-NEXT:    tst w2, #0x1
; CHECK-SD-NEXT:    csneg w0, w1, w0, eq
; CHECK-SD-NEXT:    ret
;
; CHECK-GI-LABEL: neg_select_negb:
; CHECK-GI:       // %bb.0:
; CHECK-GI-NEXT:    and w8, w2, #0x1
; CHECK-GI-NEXT:    tst w8, #0x1
; CHECK-GI-NEXT:    csneg w8, w0, w1, ne
; CHECK-GI-NEXT:    neg w0, w8
; CHECK-GI-NEXT:    ret
  %negb = sub i32 0, %b
  %sel = select i1 %bb, i32 %a, i32 %negb
  %res = sub i32 0, %sel
  ret i32 %res
}

define i32 @neg_select_ab(i32 %a, i32 %b, i1 %bb) {
; CHECK-SD-LABEL: neg_select_ab:
; CHECK-SD:       // %bb.0:
; CHECK-SD-NEXT:    tst w2, #0x1
; CHECK-SD-NEXT:    csel w8, w0, w1, ne
; CHECK-SD-NEXT:    neg w0, w8
; CHECK-SD-NEXT:    ret
;
; CHECK-GI-LABEL: neg_select_ab:
; CHECK-GI:       // %bb.0:
; CHECK-GI-NEXT:    and w8, w2, #0x1
; CHECK-GI-NEXT:    tst w8, #0x1
; CHECK-GI-NEXT:    csel w8, w0, w1, ne
; CHECK-GI-NEXT:    neg w0, w8
; CHECK-GI-NEXT:    ret
  %sel = select i1 %bb, i32 %a, i32 %b
  %res = sub i32 0, %sel
  ret i32 %res
}

define i32 @neg_select_nega_with_use(i32 %a, i32 %b, i1 %bb) {
; CHECK-SD-LABEL: neg_select_nega_with_use:
; CHECK-SD:       // %bb.0:
; CHECK-SD-NEXT:    tst w2, #0x1
; CHECK-SD-NEXT:    neg w8, w0
; CHECK-SD-NEXT:    csneg w9, w1, w0, eq
; CHECK-SD-NEXT:    sub w0, w8, w9
; CHECK-SD-NEXT:    ret
;
; CHECK-GI-LABEL: neg_select_nega_with_use:
; CHECK-GI:       // %bb.0:
; CHECK-GI-NEXT:    and w8, w2, #0x1
; CHECK-GI-NEXT:    tst w8, #0x1
; CHECK-GI-NEXT:    neg w8, w0
; CHECK-GI-NEXT:    csneg w9, w1, w0, eq
; CHECK-GI-NEXT:    sub w0, w8, w9
; CHECK-GI-NEXT:    ret
  %nega = sub i32 0, %a
  %sel = select i1 %bb, i32 %nega, i32 %b
  %nsel = sub i32 0, %sel
  %res = add i32 %nsel, %nega
  ret i32 %res
}
;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; CHECK: {{.*}}
