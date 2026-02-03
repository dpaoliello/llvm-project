; RUN: sed -e s/.tableonly:// %s | llc -mtriple=i686-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,TABLEONLY
; RUN: sed -e s/.tableonly:// %s | llc -mtriple=i686-w64-windows-gnu | FileCheck %s --check-prefixes=CHECK,TABLEONLY
; RUN: sed -e s/.normal:// %s | llc -mtriple=i686-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.normal:// %s | llc -mtriple=i686-w64-windows-gnu | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.checkindirect:// %s | llc -mtriple=i686-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.checkdirect:// %s | llc -mtriple=i686-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKDIRECT
; RUN: sed -e s/.dispatchindirect:// %s | llc -mtriple=i686-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,DISPATCHINDIRECT
; RUN: sed -e s/.dispatchdirect:// %s | llc -mtriple=i686-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,DISPATCHDIRECT
; Control Flow Guard is currently only available on Windows

declare void @target_func()

define void @func() {
entry:
  %func_ptr = alloca ptr, align 8
  store ptr @target_func, ptr %func_ptr, align 8
  %0 = load ptr, ptr %func_ptr, align 8

  call void %0()
  ret void

  ; CHECK-LABEL:            func:

  ; CHECKINDIRECT:       calll *___guard_check_icall_fptr
  ; CHECKINDIRECT-NEXT:  calll *%

  ; DISPATCHINDIRECT:      calll *___guard_dispatch_icall_fptr
  ; DISPATCHINDIRECT-NOT:  __guard_check_icall
  ; DISPATCHINDIRECT-NOT:  __guard_dispatch_icall

  ; CHECKDIRECT:       calll ___guard_check_icall
  ; CHECKDIRECT-NEXT:  calll *%
  ; CHECKDIRECT-NOT:   __guard_dispatch_icall

  ; DISPATCHDIRECT:      calll ___guard_dispatch_icall
  ; DISPATCHDIRECT-NOT:  __guard_check_icall

  ; TABLEONLY-NOT:  __guard_dispatch_icall
  ; TABLEONLY-NOT:  __guard_check_icall
  ; TABLEONLY:      calll *%
  ; TABLEONLY-NOT:  __guard_dispatch_icall
  ; TABLEONLY-NOT:  __guard_check_icall
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
