; RUN: sed -e s/.tableonly:// %s | llc -mtriple=aarch64-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,TABLEONLY
; RUN: sed -e s/.tableonly:// %s | llc -mtriple=aarch64-w64-windows-gnu | FileCheck %s --check-prefixes=CHECK,TABLEONLY
; RUN: sed -e s/.normal:// %s | llc -mtriple=aarch64-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.normal:// %s | llc -mtriple=aarch64-w64-windows-gnu | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.normal:// %s | llc -mtriple=arm64ec-pc-windows-msvc 2>&1 | FileCheck %s --check-prefixes=CHECK,ECINDIRECT,NOECWARN
; RUN: sed -e s/.checkindirect:// %s | llc -mtriple=aarch64-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.checkindirect:// %s | llc -mtriple=arm64ec-pc-windows-msvc 2>&1 | FileCheck %s --check-prefixes=CHECK,ECINDIRECT,NOECWARN
; RUN: sed -e s/.checkdirect:// %s | llc -mtriple=aarch64-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKDIRECT
; RUN: sed -e s/.checkdirect:// %s | llc -mtriple=arm64ec-pc-windows-msvc 2>&1 | FileCheck %s --check-prefixes=CHECK,ECDIRECT,NOECWARN
; RUN: sed -e s/.dispatchindirect:// %s | llc -mtriple=aarch64-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,DISPATCHINDIRECT
; RUN: sed -e s/.dispatchindirect:// %s | llc -mtriple=arm64ec-pc-windows-msvc 2>&1 | FileCheck %s --check-prefixes=CHECK,ECINDIRECT,ECWARN
; RUN: sed -e s/.dispatchdirect:// %s | llc -mtriple=aarch64-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,DISPATCHDIRECT
; RUN: sed -e s/.dispatchdirect:// %s | llc -mtriple=arm64ec-pc-windows-msvc 2>&1 | FileCheck %s --check-prefixes=CHECK,ECDIRECT,ECWARN
; Control Flow Guard is currently only available on Windows

declare void @target_func()

; NOECWARN-NOT: warning:
; ECWARN: warning: only the Check Control Flow Guard mechanism is supported for Arm64EC

define void @func() {
entry:
  %func_ptr = alloca ptr, align 8
  store ptr @target_func, ptr %func_ptr, align 8
  %0 = load ptr, ptr %func_ptr, align 8

  call void %0()
  ret void

  ; CHECK-LABEL:            {{("#)?}}func{{"?}}:

  ; CHECKINDIRECT:       adrp    x8, __guard_check_icall_fptr
  ; CHECKINDIRECT:       ldr     x9, [x8, :lo12:__guard_check_icall_fptr]
  ; CHECKINDIRECT:       adrp    x8, target_func
  ; CHECKINDIRECT:       add     x8, x8, :lo12:target_func
  ; CHECKINDIRECT:       mov     x15, x8
  ; CHECKINDIRECT:       blr     x9
  ; CHECKINDIRECT-NEXT:  blr     x8

  ; DISPATCHINDIRECT:       adrp    x8, __guard_dispatch_icall_fptr
  ; DISPATCHINDIRECT:       adrp    x9, target_func
  ; DISPATCHINDIRECT:       add     x9, x9, :lo12:target_func
  ; DISPATCHINDIRECT:       ldr     x8, [x8, :lo12:__guard_dispatch_icall_fptr]
  ; DISPATCHINDIRECT:       blr     x8

  ; CHECKDIRECT:       adrp    x8, target_func
  ; CHECKDIRECT:       add     x8, x8, :lo12:target_func
  ; CHECKDIRECT:       mov     x15, x8
  ; CHECKDIRECT:       bl      __guard_check_icall
  ; CHECKDIRECT-NEXT:  blr     x8

  ; DISPATCHDIRECT:       adrp    x9, target_func
  ; DISPATCHDIRECT:       add     x9, x9, :lo12:target_func
  ; DISPATCHDIRECT:       bl      __guard_dispatch_icall

  ; TABLEONLY-NOT:  __guard_dispatch_icall
  ; TABLEONLY-NOT:  __guard_check_icall
  ; TABLEONLY-NOT:  _check_icall_cfg
  ; TABLEONLY:      blr     x8
  ; TABLEONLY-NOT:  __guard_dispatch_icall
  ; TABLEONLY-NOT:  __guard_check_icall
  ; TABLEONLY-NOT:  _check_icall_cfg

  ; Arm64EC Always uses check
  ; ECINDIRECT:       adrp    x8, __os_arm64x_check_icall_cfg
  ; ECINDIRECT:       adrp    x11, target_func
  ; ECINDIRECT:       add     x11, x11, :lo12:target_fun
  ; ECINDIRECT:       ldr     x8, [x8, :lo12:__os_arm64x_check_icall_cfg]
  ; ECINDIRECT:       blr     x8
  ; ECINDIRECT-NEXT:  blr     x11

  ; ECDIRECT:       adrp    x11, target_func
  ; ECDIRECT:       add     x11, x11, :lo12:target_func
  ; ECDIRECT:       bl      "#__os_arm64x_direct_check_icall_cfg"
  ; ECDIRECT-NEXT:  blr     x11
}

; CHECK: .section        .gfids$y,"dr"

!0 = !{i32 2, !"cfguard", i32 1}
!1 = !{i32 2, !"cfguard", i32 2}
!2 = !{i32 2, !"cfguard-mechanism", i32 1}
!3 = !{i32 2, !"cfguard-mechanism", i32 2}
!4 = !{i32 2, !"cfguard-call-kind", i32 1}
!5 = !{i32 2, !"cfguard-call-kind", i32 2}
;tableonly: !llvm.module.flags = !{!0}
;normal:    !llvm.module.flags = !{!1}
;checkdirect:     !llvm.module.flags = !{!1, !2, !4}
;dispatchdirect:  !llvm.module.flags = !{!1, !3, !4}
;checkindirect:     !llvm.module.flags = !{!1, !2, !5}
;dispatchindirect:  !llvm.module.flags = !{!1, !3, !5}
