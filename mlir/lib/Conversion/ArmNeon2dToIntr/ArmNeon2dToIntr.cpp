//===- ArmNeon2dToIntr.cpp - convert Arm Neon 2d ops to intrinsics --------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/ArmNeon2dToIntr/ArmNeon2dToIntr.h"

#include "mlir/Dialect/ArmNeon/ArmNeonDialect.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

namespace mlir {
#define GEN_PASS_DEF_CONVERTARMNEON2DTOINTRPASS
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::arm_neon;

namespace {

class Sdot2dLoweringPattern : public OpRewritePattern<Sdot2dOp> {
public:
  using OpRewritePattern::OpRewritePattern;

  /// Convert to 1-dimensional vector type to match the requirements of
  /// arm.neon.intr.sdot
  LogicalResult matchAndRewrite(Sdot2dOp op,
                                PatternRewriter &rewriter) const override {
    Type elemType = cast<VectorType>(op.getB().getType()).getElementType();
    int length = cast<VectorType>(op.getB().getType()).getShape()[0] *
                 Sdot2dOp::kReductionSize;
    VectorType flattenedVectorType = VectorType::get({length}, elemType);
    Value b2d = op.getB();
    Value c2d = op.getC();
    Location loc = op.getLoc();
    Value b1d =
        vector::ShapeCastOp::create(rewriter, loc, flattenedVectorType, b2d);
    Value c1d =
        vector::ShapeCastOp::create(rewriter, loc, flattenedVectorType, c2d);
    Value newOp = SdotOp::create(rewriter, loc, op.getRes().getType(),
                                 op.getA(), b1d, c1d);
    rewriter.replaceOp(op, {newOp});
    return success();
  }
};

class ConvertArmNeon2dToIntr
    : public impl::ConvertArmNeon2dToIntrPassBase<ConvertArmNeon2dToIntr> {
  void runOnOperation() override {
    auto *context = &getContext();

    RewritePatternSet patterns(context);
    populateConvertArmNeon2dToIntrPatterns(patterns);

    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      return signalPassFailure();
  }
};

} // namespace

void mlir::populateConvertArmNeon2dToIntrPatterns(RewritePatternSet &patterns) {
  patterns.add<Sdot2dLoweringPattern>(patterns.getContext());
}
