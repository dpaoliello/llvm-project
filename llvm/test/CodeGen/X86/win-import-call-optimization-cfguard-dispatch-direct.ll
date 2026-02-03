; RUN: llc -mtriple=x86_64-pc-windows-msvc -o - %s | FileCheck %s
; RUN: llc --fast-isel -mtriple=x86_64-pc-windows-msvc -o - %s | FileCheck %s
; RUN: llc --global-isel --global-isel-abort=2 -mtriple=x86_64-pc-windows-msvc -o - %s | FileCheck %s

@global_func_ptr = external dso_local local_unnamed_addr global ptr, align 8
declare dso_local i32 @__C_specific_handler(...)

define dso_local void @normal_call(ptr noundef readonly %func_ptr) local_unnamed_addr section "nc_sect" {
entry:
  call void %func_ptr()
  %0 = load ptr, ptr @global_func_ptr, align 8
  call void %0()
  ret void
}
; CHECK-LABEL:  normal_call:
; CHECK:          movq    %rcx, %rax
; CHECK-NEXT:     callq   __guard_dispatch_icall
; CHECK-NEXT:     movq    global_func_ptr(%rip), %rax
; CHECK-NEXT:     callq   __guard_dispatch_icall

define dso_local void @tail_call_fp(ptr noundef readonly %func_ptr) local_unnamed_addr section "tc_sect" {
entry:
  tail call void %func_ptr()
  ret void
}
; CHECK-LABEL:  tail_call_fp:
; CHECK:          movq    %rcx, %rax
; CHECK-NEXT:     jmp     __guard_dispatch_icall

define dso_local void @tail_call_global_fp(ptr noundef readonly %func_ptr) local_unnamed_addr section "tc_sect" {
entry:
  %0 = load ptr, ptr @global_func_ptr, align 8
  tail call void %0()
  ret void
}
; CHECK-LABEL:  tail_call_global_fp:
; CHECK:          movq    global_func_ptr(%rip), %rax
; CHECK-NEXT:     jmp     __guard_dispatch_icall

define dso_local void @invoke_many_args(ptr %0, ptr %1, ptr %2) personality ptr @__C_specific_handler {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  invoke void %0(ptr %1, ptr %2, ptr %4, ptr %5, ptr %6)
          to label %7 unwind label %8

7:
  ret void

8:
  %9 = cleanuppad within none []
  cleanupret from %9 unwind to caller
}
; CHECK-LABEL:  invoke_many_args:
; CHECK:          movq    %rcx, %rax
; CHECK-NOT:      rax
; CHECK:          callq   __guard_dispatch_icall

; There's not calls that require import call optimization metadata, so it should
; be empty.
; CHECK-LABEL  .section   .retplne,"yi"
; CHECK-NEXT   .asciz  "RetpolineV1"
; CHECK-NOT    .long

!llvm.module.flags = !{!0, !1, !2, !3}
!0 = !{i32 1, !"import-call-optimization", i32 1}
!1 = !{i32 2, !"cfguard", i32 2}
!2 = !{i32 2, !"cfguard-mechanism", i32 2}
!3 = !{i32 2, !"cfguard-call-kind", i32 1}
