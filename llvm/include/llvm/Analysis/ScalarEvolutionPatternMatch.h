//===----------------------------------------------------------------------===//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides a simple and efficient mechanism for performing general
// tree-based pattern matches on SCEVs, based on LLVM's IR pattern matchers.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_ANALYSIS_SCALAREVOLUTIONPATTERNMATCH_H
#define LLVM_ANALYSIS_SCALAREVOLUTIONPATTERNMATCH_H

#include "llvm/Analysis/ScalarEvolutionExpressions.h"

namespace llvm {
namespace SCEVPatternMatch {

template <typename Pattern> bool match(const SCEV *S, const Pattern &P) {
  return P.match(S);
}

template <typename Predicate> struct cst_pred_ty : public Predicate {
  cst_pred_ty() = default;
  cst_pred_ty(uint64_t V) : Predicate(V) {}
  bool match(const SCEV *S) const {
    assert((isa<SCEVCouldNotCompute>(S) || !S->getType()->isVectorTy()) &&
           "no vector types expected from SCEVs");
    auto *C = dyn_cast<SCEVConstant>(S);
    return C && this->isValue(C->getAPInt());
  }
};

struct is_zero {
  bool isValue(const APInt &C) const { return C.isZero(); }
};

/// Match an integer 0.
inline cst_pred_ty<is_zero> m_scev_Zero() { return cst_pred_ty<is_zero>(); }

struct is_one {
  bool isValue(const APInt &C) const { return C.isOne(); }
};

/// Match an integer 1.
inline cst_pred_ty<is_one> m_scev_One() { return cst_pred_ty<is_one>(); }

struct is_all_ones {
  bool isValue(const APInt &C) const { return C.isAllOnes(); }
};

/// Match an integer with all bits set.
inline cst_pred_ty<is_all_ones> m_scev_AllOnes() {
  return cst_pred_ty<is_all_ones>();
}

template <typename Class> struct class_match {
  template <typename ITy> bool match(ITy *V) const { return isa<Class>(V); }
};

inline class_match<const SCEV> m_SCEV() { return class_match<const SCEV>(); }
inline class_match<const SCEVConstant> m_SCEVConstant() {
  return class_match<const SCEVConstant>();
}
inline class_match<const SCEVVScale> m_SCEVVScale() {
  return class_match<const SCEVVScale>();
}

template <typename Class> struct bind_ty {
  Class *&VR;

  bind_ty(Class *&V) : VR(V) {}

  template <typename ITy> bool match(ITy *V) const {
    if (auto *CV = dyn_cast<Class>(V)) {
      VR = CV;
      return true;
    }
    return false;
  }
};

/// Match a SCEV, capturing it if we match.
inline bind_ty<const SCEV> m_SCEV(const SCEV *&V) { return V; }
inline bind_ty<const SCEVConstant> m_SCEVConstant(const SCEVConstant *&V) {
  return V;
}
inline bind_ty<const SCEVUnknown> m_SCEVUnknown(const SCEVUnknown *&V) {
  return V;
}

inline bind_ty<const SCEVAddExpr> m_scev_Add(const SCEVAddExpr *&V) {
  return V;
}

/// Match a specified const SCEV *.
struct specificscev_ty {
  const SCEV *Expr;

  specificscev_ty(const SCEV *Expr) : Expr(Expr) {}

  template <typename ITy> bool match(ITy *S) const { return S == Expr; }
};

/// Match if we have a specific specified SCEV.
inline specificscev_ty m_scev_Specific(const SCEV *S) { return S; }

struct is_specific_cst {
  uint64_t CV;
  is_specific_cst(uint64_t C) : CV(C) {}
  bool isValue(const APInt &C) const { return C == CV; }
};

/// Match an SCEV constant with a plain unsigned integer.
inline cst_pred_ty<is_specific_cst> m_scev_SpecificInt(uint64_t V) { return V; }

struct bind_cst_ty {
  const APInt *&CR;

  bind_cst_ty(const APInt *&Op0) : CR(Op0) {}

  bool match(const SCEV *S) const {
    assert((isa<SCEVCouldNotCompute>(S) || !S->getType()->isVectorTy()) &&
           "no vector types expected from SCEVs");
    auto *C = dyn_cast<SCEVConstant>(S);
    if (!C)
      return false;
    CR = &C->getAPInt();
    return true;
  }
};

/// Match an SCEV constant and bind it to an APInt.
inline bind_cst_ty m_scev_APInt(const APInt *&C) { return C; }

/// Match a unary SCEV.
template <typename SCEVTy, typename Op0_t> struct SCEVUnaryExpr_match {
  Op0_t Op0;

  SCEVUnaryExpr_match(Op0_t Op0) : Op0(Op0) {}

  bool match(const SCEV *S) const {
    auto *E = dyn_cast<SCEVTy>(S);
    return E && E->getNumOperands() == 1 && Op0.match(E->getOperand(0));
  }
};

template <typename SCEVTy, typename Op0_t>
inline SCEVUnaryExpr_match<SCEVTy, Op0_t> m_scev_Unary(const Op0_t &Op0) {
  return SCEVUnaryExpr_match<SCEVTy, Op0_t>(Op0);
}

template <typename Op0_t>
inline SCEVUnaryExpr_match<SCEVSignExtendExpr, Op0_t>
m_scev_SExt(const Op0_t &Op0) {
  return m_scev_Unary<SCEVSignExtendExpr>(Op0);
}

template <typename Op0_t>
inline SCEVUnaryExpr_match<SCEVZeroExtendExpr, Op0_t>
m_scev_ZExt(const Op0_t &Op0) {
  return m_scev_Unary<SCEVZeroExtendExpr>(Op0);
}

template <typename Op0_t>
inline SCEVUnaryExpr_match<SCEVPtrToIntExpr, Op0_t>
m_scev_PtrToInt(const Op0_t &Op0) {
  return SCEVUnaryExpr_match<SCEVPtrToIntExpr, Op0_t>(Op0);
}

/// Match a binary SCEV.
template <typename SCEVTy, typename Op0_t, typename Op1_t>
struct SCEVBinaryExpr_match {
  Op0_t Op0;
  Op1_t Op1;

  SCEVBinaryExpr_match(Op0_t Op0, Op1_t Op1) : Op0(Op0), Op1(Op1) {}

  bool match(const SCEV *S) const {
    auto *E = dyn_cast<SCEVTy>(S);
    return E && E->getNumOperands() == 2 && Op0.match(E->getOperand(0)) &&
           Op1.match(E->getOperand(1));
  }
};

template <typename SCEVTy, typename Op0_t, typename Op1_t>
inline SCEVBinaryExpr_match<SCEVTy, Op0_t, Op1_t>
m_scev_Binary(const Op0_t &Op0, const Op1_t &Op1) {
  return SCEVBinaryExpr_match<SCEVTy, Op0_t, Op1_t>(Op0, Op1);
}

template <typename Op0_t, typename Op1_t>
inline SCEVBinaryExpr_match<SCEVAddExpr, Op0_t, Op1_t>
m_scev_Add(const Op0_t &Op0, const Op1_t &Op1) {
  return m_scev_Binary<SCEVAddExpr>(Op0, Op1);
}

template <typename Op0_t, typename Op1_t>
inline SCEVBinaryExpr_match<SCEVMulExpr, Op0_t, Op1_t>
m_scev_Mul(const Op0_t &Op0, const Op1_t &Op1) {
  return m_scev_Binary<SCEVMulExpr>(Op0, Op1);
}

template <typename Op0_t, typename Op1_t>
inline SCEVBinaryExpr_match<SCEVUDivExpr, Op0_t, Op1_t>
m_scev_UDiv(const Op0_t &Op0, const Op1_t &Op1) {
  return m_scev_Binary<SCEVUDivExpr>(Op0, Op1);
}

inline class_match<const Loop> m_Loop() { return class_match<const Loop>(); }

/// Match an affine SCEVAddRecExpr.
template <typename Op0_t, typename Op1_t, typename Loop_t>
struct SCEVAffineAddRec_match {
  SCEVBinaryExpr_match<SCEVAddRecExpr, Op0_t, Op1_t> Ops;
  Loop_t Loop;

  SCEVAffineAddRec_match(Op0_t Op0, Op1_t Op1, Loop_t Loop)
      : Ops(Op0, Op1), Loop(Loop) {}

  bool match(const SCEV *S) const {
    return Ops.match(S) && Loop.match(cast<SCEVAddRecExpr>(S)->getLoop());
  }
};

/// Match a specified const Loop*.
struct specificloop_ty {
  const Loop *L;

  specificloop_ty(const Loop *L) : L(L) {}

  bool match(const Loop *L) const { return L == this->L; }
};

inline specificloop_ty m_SpecificLoop(const Loop *L) { return L; }

inline bind_ty<const Loop> m_Loop(const Loop *&L) { return L; }

template <typename Op0_t, typename Op1_t>
inline SCEVAffineAddRec_match<Op0_t, Op1_t, class_match<const Loop>>
m_scev_AffineAddRec(const Op0_t &Op0, const Op1_t &Op1) {
  return SCEVAffineAddRec_match<Op0_t, Op1_t, class_match<const Loop>>(
      Op0, Op1, m_Loop());
}

template <typename Op0_t, typename Op1_t, typename Loop_t>
inline SCEVAffineAddRec_match<Op0_t, Op1_t, Loop_t>
m_scev_AffineAddRec(const Op0_t &Op0, const Op1_t &Op1, const Loop_t &L) {
  return SCEVAffineAddRec_match<Op0_t, Op1_t, Loop_t>(Op0, Op1, L);
}

} // namespace SCEVPatternMatch
} // namespace llvm

#endif
