; RUN: sed -e s/.tableonly:// %s | llc -mtriple=arm-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,TABLEONLY
; RUN: sed -e s/.tableonly:// %s | llc -mtriple=arm-w64-windows-gnu | FileCheck %s --check-prefixes=CHECK,TABLEONLY
; RUN: sed -e s/.normal:// %s | llc -mtriple=arm-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.normal:// %s | llc -mtriple=arm-w64-windows-gnu | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.checkindirect:// %s | llc -mtriple=arm-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKINDIRECT
; RUN: sed -e s/.checkdirect:// %s | llc -mtriple=arm-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,CHECKDIRECT
; RUN: sed -e s/.dispatchindirect:// %s | llc -mtriple=arm-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,DISPATCHINDIRECT
; RUN: sed -e s/.dispatchdirect:// %s | llc -mtriple=arm-pc-windows-msvc | FileCheck %s --check-prefixes=CHECK,DISPATCHDIRECT
; Control Flow Guard is currently only available on Windows

declare void @target_func()

define void @func() #0 {
entry:
  %func_ptr = alloca ptr, align 8
  store ptr @target_func, ptr %func_ptr, align 8
  %0 = load ptr, ptr %func_ptr, align 8

  call void %0()
  ret void

  ; CHECK-LABEL:            func:

  ; CHECKINDIRECT:       movw r0, :lower16:__guard_check_icall_fptr
  ; CHECKINDIRECT:       ldr r1, [r0]
  ; CHECKINDIRECT:       movw r4, :lower16:target_func
  ; CHECKINDIRECT:       blx r1
  ; CHECKINDIRECT-NEXT:  blx r4

  ; DISPATCHINDIRECT:       movw r0, :lower16:__guard_dispatch_icall_fptr
  ; DISPATCHINDIRECT:       ldr r1, [r0]
  ; DISPATCHINDIRECT:       movw r0, :lower16:target_func
  ; DISPATCHINDIRECT:       blx r1

  ; CHECKDIRECT:       movw r4, :lower16:target_func
  ; CHECKDIRECT:       bl      __guard_check_icall
  ; CHECKDIRECT-NEXT:  blx r4

  ; DISPATCHDIRECT:       movw r0, :lower16:target_func
  ; DISPATCHDIRECT:       bl      __guard_dispatch_icall

  ; TABLEONLY-NOT:  __guard_dispatch_icall
  ; TABLEONLY-NOT:  __guard_check_icall
  ; TABLEONLY:      blx r0
  ; TABLEONLY-NOT:  __guard_dispatch_icall
  ; TABLEONLY-NOT:  __guard_check_icall
}
attributes #0 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "frame-pointer"="all" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="cortex-a9" "target-features"="+armv7-a,+dsp,+fp16,+neon,+strict-align,+thumb-mode,+vfp3" "use-soft-float"="false"}

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
