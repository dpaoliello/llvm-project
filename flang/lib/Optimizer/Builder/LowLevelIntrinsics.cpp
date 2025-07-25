//===-- LowLevelIntrinsics.cpp --------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Coding style: https://mlir.llvm.org/getting_started/DeveloperGuide/
//
//===----------------------------------------------------------------------===//
//
// Low level intrinsic functions.
//
// These include LLVM intrinsic calls and standard C library calls.
// Target-specific calls, such as OS functions, should be factored in other
// file(s).
//
//===----------------------------------------------------------------------===//

#include "flang/Optimizer/Builder/LowLevelIntrinsics.h"
#include "flang/Optimizer/Builder/FIRBuilder.h"

mlir::func::FuncOp fir::factory::getRealloc(fir::FirOpBuilder &builder) {
  auto ptrTy = builder.getRefType(builder.getIntegerType(8));
  llvm::SmallVector<mlir::Type> args = {ptrTy, builder.getI64Type()};
  auto reallocTy = mlir::FunctionType::get(builder.getContext(), args, {ptrTy});
  return builder.createFunction(builder.getUnknownLoc(), "realloc", reallocTy);
}

mlir::func::FuncOp
fir::factory::getLlvmGetRounding(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy = mlir::FunctionType::get(builder.getContext(), {}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "llvm.get.rounding",
                                funcTy);
}

mlir::func::FuncOp
fir::factory::getLlvmSetRounding(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy = mlir::FunctionType::get(builder.getContext(), {int32Ty}, {});
  return builder.createFunction(builder.getUnknownLoc(), "llvm.set.rounding",
                                funcTy);
}

mlir::func::FuncOp
fir::factory::getLlvmInitTrampoline(fir::FirOpBuilder &builder) {
  auto ptrTy = builder.getRefType(builder.getIntegerType(8));
  auto funcTy =
      mlir::FunctionType::get(builder.getContext(), {ptrTy, ptrTy, ptrTy}, {});
  return builder.createFunction(builder.getUnknownLoc(), "llvm.init.trampoline",
                                funcTy);
}

mlir::func::FuncOp
fir::factory::getLlvmAdjustTrampoline(fir::FirOpBuilder &builder) {
  auto ptrTy = builder.getRefType(builder.getIntegerType(8));
  auto funcTy = mlir::FunctionType::get(builder.getContext(), {ptrTy}, {ptrTy});
  return builder.createFunction(builder.getUnknownLoc(),
                                "llvm.adjust.trampoline", funcTy);
}

mlir::func::FuncOp fir::factory::getFeclearexcept(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy =
      mlir::FunctionType::get(builder.getContext(), {int32Ty}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "feclearexcept",
                                funcTy);
}

mlir::func::FuncOp
fir::factory::getFedisableexcept(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy =
      mlir::FunctionType::get(builder.getContext(), {int32Ty}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "fedisableexcept",
                                funcTy);
}

mlir::func::FuncOp fir::factory::getFeenableexcept(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy =
      mlir::FunctionType::get(builder.getContext(), {int32Ty}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "feenableexcept",
                                funcTy);
}

mlir::func::FuncOp fir::factory::getFegetexcept(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy = mlir::FunctionType::get(builder.getContext(), {}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "fegetexcept", funcTy);
}

mlir::func::FuncOp fir::factory::getFeraiseexcept(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy =
      mlir::FunctionType::get(builder.getContext(), {int32Ty}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "feraiseexcept",
                                funcTy);
}

mlir::func::FuncOp fir::factory::getFetestexcept(fir::FirOpBuilder &builder) {
  auto int32Ty = builder.getIntegerType(32);
  auto funcTy =
      mlir::FunctionType::get(builder.getContext(), {int32Ty}, {int32Ty});
  return builder.createFunction(builder.getUnknownLoc(), "fetestexcept",
                                funcTy);
}
