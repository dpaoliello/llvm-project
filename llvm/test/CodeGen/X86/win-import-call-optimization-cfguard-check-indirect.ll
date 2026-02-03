; RUN: llc -mtriple=x86_64-pc-windows-msvc -o - %s | FileCheck %s

@global_func_ptr = external dso_local local_unnamed_addr global ptr, align 8
declare dllimport void @a() local_unnamed_addr
declare dllimport void @b() local_unnamed_addr

define dso_local void @normal_call(ptr noundef readonly %func_ptr) local_unnamed_addr section "nc_sect" {
entry:
  call void @a()
  call void @a()
  call void %func_ptr()
  %0 = load ptr, ptr @global_func_ptr, align 8
  call void %0()
  ret void
}
; CHECK-LABEL:  normal_call:
; CHECK:        .Limpcall0:
; CHECK-NEXT:     rex64
; CHECK-NEXT:     callq   *__imp_a(%rip)
; CHECK-NEXT:     {disp8} nopl    (%rax,%rax)
; CHECK-NEXT:   .Limpcall1:
; CHECK-NEXT:     rex64
; CHECK-NEXT:     callq   *__imp_a(%rip)
; CHECK-NEXT:     {disp8} nopl    (%rax,%rax)
; CHECK-NEXT:     movq    __guard_check_icall_fptr(%rip), %rax
; CHECK-NEXT:     movq    %rbx, %rcx
; CHECK-NEXT:   .Limpcall2:
; CHECK-NEXT:     callq   *%rax
; CHECK-NEXT:     nopl    (%rax)
; CHECK-NEXT:     movq    %rbx, %rax
; CHECK-NEXT:   .Limpcall3:
; CHECK-NEXT:     callq   *%rax
; CHECK-NEXT:     nopl    (%rax)
; CHECK-NEXT:     movq    global_func_ptr(%rip), %rcx
; CHECK-NEXT:     movq    __guard_check_icall_fptr(%rip), %rax
; CHECK-NEXT:   .Limpcall4:
; CHECK-NEXT:     callq   *%rax
; CHECK-NEXT:     nopl    (%rax)
; CHECK-NEXT:     movq    %rcx, %rax
; CHECK-NEXT:   .Limpcall5:
; CHECK-NEXT:     callq   *%rax
; CHECK-NEXT:     nopl    (%rax)

define dso_local void @tail_call() local_unnamed_addr section "tc_sect" {
entry:
  tail call void @b()
  ret void
}
; CHECK-LABEL:  tail_call:
; CHECK:        .Limpcall6:
; CHECK-NEXT:     rex64 jmpq *__imp_b(%rip)

define dso_local void @tail_call_fp(ptr noundef readonly %func_ptr) local_unnamed_addr section "tc_sect" {
entry:
  tail call void %func_ptr()
  ret void
}
; CHECK-LABEL:  tail_call_fp:
; CHECK:          movq    __guard_check_icall_fptr(%rip), %rax
; CHECK-NEXT:   .Limpcall7:
; CHECK-NEXT:     callq   *%rax
; CHECK-NEXT:     nopl    (%rax)
; CHECK-NEXT:     movq    %rcx, %rax
; CHECK-NOT:      rax
; CHECK:        .Limpcall8:
; CHECK-NEXT:     rex64 jmpq      *%rax
; CHECK-NEXT:     int3
; CHECK-NEXT:     int3

define dso_local void @tail_call_global_fp(ptr noundef readonly %func_ptr) local_unnamed_addr section "tc_sect" {
entry:
  %0 = load ptr, ptr @global_func_ptr, align 8
  tail call void %0()
  ret void
}
; CHECK-LABEL:  tail_call_global_fp:
; CHECK:          movq    global_func_ptr(%rip), %rcx
; CHECK-NEXT:     movq    __guard_check_icall_fptr(%rip), %rax
; CHECK-NEXT:   .Limpcall9:
; CHECK-NEXT:     callq   *%rax
; CHECK-NEXT:     nopl    (%rax)
; CHECK-NEXT:     movq    %rcx, %rax
; CHECK-NOT:      rax
; CHECK:        .Limpcall10:
; CHECK-NEXT:     rex64 jmpq      *%rax
; CHECK-NEXT:     int3
; CHECK-NEXT:     int3

; There is NO special encoding for Control Flow Guard "check" function calls,
; so we expect to see the normal 2, 3, 5, 6 but NOT 9 or 10.
; CHECK-LABEL  .section   .retplne,"yi"
; CHECK-NEXT   .asciz  "RetpolineV1"
; CHECK-NEXT   .long   56
; CHECK-NEXT   .secnum nc_sect
; CHECK-NEXT   .long   3
; CHECK-NEXT   .secoffset      .Limpcall0
; CHECK-NEXT   .long   3
; CHECK-NEXT   .secoffset      .Limpcall1
; CHECK-NEXT   .long   5
; CHECK-NEXT   .secoffset      .Limpcall2
; CHECK-NEXT   .long   5
; CHECK-NEXT   .secoffset      .Limpcall3
; CHECK-NEXT   .long   5
; CHECK-NEXT   .secoffset      .Limpcall4
; CHECK-NEXT   .long   5
; CHECK-NEXT   .secoffset      .Limpcall5
; CHECK-NEXT   .long   48
; CHECK-NEXT   .secnum tc_sect
; CHECK-NEXT   .long   2
; CHECK-NEXT   .secoffset      .Limpcall6
; CHECK-NEXT   .long   5
; CHECK-NEXT   .secoffset      .Limpcall7
; CHECK-NEXT   .long   6
; CHECK-NEXT   .secoffset      .Limpcall8
; CHECK-NEXT   .long   5
; CHECK-NEXT   .secoffset      .Limpcall9
; CHECK-NEXT   .long   6
; CHECK-NEXT   .secoffset      .Limpcall10

!llvm.module.flags = !{!0, !1, !2, !3}
!0 = !{i32 1, !"import-call-optimization", i32 1}
!1 = !{i32 2, !"cfguard", i32 2}
!2 = !{i32 2, !"cfguard-mechanism", i32 1}
!3 = !{i32 2, !"cfguard-call-kind", i32 2}
