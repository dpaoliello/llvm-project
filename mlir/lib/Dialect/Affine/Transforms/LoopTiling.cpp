//===- LoopTiling.cpp --- Loop tiling pass ------------------------------*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements a pass to tile affine loop nests.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/Affine/Passes.h"

#include "mlir/Dialect/Affine/Analysis/AffineAnalysis.h"
#include "mlir/Dialect/Affine/Analysis/AffineStructures.h"
#include "mlir/Dialect/Affine/Analysis/LoopAnalysis.h"
#include "mlir/Dialect/Affine/Analysis/Utils.h"
#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Affine/LoopUtils.h"
#include "mlir/Dialect/Affine/Utils.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include <optional>

namespace mlir {
namespace affine {
#define GEN_PASS_DEF_AFFINELOOPTILING
#include "mlir/Dialect/Affine/Passes.h.inc"
} // namespace affine
} // namespace mlir

using namespace mlir;
using namespace mlir::affine;

#define DEBUG_TYPE "affine-loop-tile"

namespace {

/// A pass to perform loop tiling on all suitable loop nests of a func op.
struct LoopTiling : public affine::impl::AffineLoopTilingBase<LoopTiling> {
  LoopTiling() = default;
  explicit LoopTiling(uint64_t cacheSizeBytes, bool avoidMaxMinBounds = true)
      : avoidMaxMinBounds(avoidMaxMinBounds) {
    this->cacheSizeInKiB = cacheSizeBytes / 1024;
  }

  void runOnOperation() override;
  void getTileSizes(ArrayRef<AffineForOp> band,
                    SmallVectorImpl<unsigned> *tileSizes);

  // Default tile size if nothing is provided.
  constexpr static unsigned kDefaultTileSize = 4;

  // If true, tile sizes are set to avoid max/min in bounds if possible.
  bool avoidMaxMinBounds = true;
};

} // namespace

/// Get bands of loops that are valid to tile from the top-level of `f`.
static void
getTopLevelTileableBands(func::FuncOp f,
                         std::vector<SmallVector<AffineForOp, 6>> &bands) {
  // Get maximal perfect nest of 'affine.for' ops starting from root
  // (inclusive).
  for (AffineForOp forOp : f.getOps<AffineForOp>()) {
    SmallVector<AffineForOp, 6> band;
    getPerfectlyNestedLoops(band, forOp);
    if (isTilingValid(band))
      bands.push_back(band);
  }
}

/// Creates a pass to perform loop tiling on all suitable loop nests of a
/// Function.
std::unique_ptr<OperationPass<func::FuncOp>>
mlir::affine::createLoopTilingPass(uint64_t cacheSizeBytes) {
  return std::make_unique<LoopTiling>(cacheSizeBytes);
}
std::unique_ptr<OperationPass<func::FuncOp>>
mlir::affine::createLoopTilingPass() {
  return std::make_unique<LoopTiling>();
}

/// Reduces each tile size to the largest divisor of the corresponding trip
/// count (if the trip count is known).
static void adjustToDivisorsOfTripCounts(ArrayRef<AffineForOp> band,
                                         SmallVectorImpl<unsigned> *tileSizes) {
  assert(band.size() == tileSizes->size() && "invalid tile size count");
  for (unsigned i = 0, e = band.size(); i < e; i++) {
    unsigned &tSizeAdjusted = (*tileSizes)[i];
    std::optional<uint64_t> mayConst = getConstantTripCount(band[i]);
    if (!mayConst)
      continue;
    // Adjust the tile size to largest factor of the trip count less than
    // tSize.
    uint64_t constTripCount = *mayConst;
    if (constTripCount > 1 && tSizeAdjusted > constTripCount / 2)
      tSizeAdjusted = constTripCount / 2;
    while (constTripCount % tSizeAdjusted != 0)
      tSizeAdjusted--;
  }
}

// Returns tile sizes to use. Checks CL options; if none are specified, sets it
// based on a simple model that looks at the memory footprint and determines
// tile sizes assuming identity accesses / 1:1 tile size proportional footprint
// along each of the dimensions being tiled.
// TODO: evolve this model. Tile size determination is a large area
// to play with in general.
void LoopTiling::getTileSizes(ArrayRef<AffineForOp> band,
                              SmallVectorImpl<unsigned> *tileSizes) {
  if (band.empty())
    return;

  // Use command-line tileSize for all loops if specified.
  if (tileSize) {
    tileSizes->assign(band.size(), tileSize);
    return;
  }

  // Use supplied tile sizes and fill them with default tile size if it's short.
  if (!this->tileSizes.empty()) {
    tileSizes->assign(this->tileSizes.begin(), this->tileSizes.end());
    tileSizes->resize(band.size(), kDefaultTileSize);
    return;
  }
  tileSizes->resize(band.size());

  // If the cache size is zero, set the minimum valid tile size. No good reason
  // to pick another specific size over this.
  if (cacheSizeInKiB == 0) {
    llvm::fill(*tileSizes, 1);
    return;
  }

  // Obtain memory footprint and set tile sizes so that a tile fits in
  // the cache size. This is an approximation with the assumption that the
  // footprint increases with the tile size linearly in that dimension (i.e.,
  // assumes one-to-one access function).
  std::optional<int64_t> fp = getMemoryFootprintBytes(band[0], 0);
  if (!fp) {
    // Fill with default tile sizes if footprint is unknown.
    llvm::fill(*tileSizes, LoopTiling::kDefaultTileSize);
    if (avoidMaxMinBounds)
      adjustToDivisorsOfTripCounts(band, tileSizes);
    // The first loop in the band.
    AffineForOp rootForOp = band[0];
    (void)rootForOp;
    LLVM_DEBUG(
        rootForOp.emitWarning("memory footprint unknown: using default tile "
                              "sizes adjusted to trip count divisors"));
    return;
  }

  // Check how many times larger the cache size is when compared to footprint.
  uint64_t cacheSizeBytes = cacheSizeInKiB * 1024;
  uint64_t excessFactor = llvm::divideCeil(*fp, cacheSizeBytes);
  if (excessFactor <= 1) {
    // No need of any tiling - set tile size to 1.
    llvm::fill(*tileSizes, 1);
    return;
  }

  // Divide all loops equally in an attempt to reduce footprint.
  // TODO: this is approximate. Ideally, obtain reuse factor /
  // profitability along each dimension and weight tile sizes based on that as
  // one possible approach. Or compute a polynomial in tile sizes and solve for
  // it.

  // For an n-d tileable band, compute the n^th root of the excess.
  unsigned tSize =
      static_cast<unsigned>(floorl(std::pow(excessFactor, 1.0 / band.size())));
  // We'll keep a running product to determine the last tile size better.
  unsigned cumulProductOfTileSizes = 1;
  for (unsigned i = 0, e = band.size(); i < e; i++) {
    if (i < e - 1)
      (*tileSizes)[i] = tSize;
    else
      // Set last tile size to cover the balance.
      (*tileSizes)[i] = std::max(
          1U, static_cast<unsigned>(excessFactor / cumulProductOfTileSizes));
    cumulProductOfTileSizes *= (*tileSizes)[i];
  }
  if (avoidMaxMinBounds)
    adjustToDivisorsOfTripCounts(band, tileSizes);
}

void LoopTiling::runOnOperation() {
  // Bands of loops to tile.
  std::vector<SmallVector<AffineForOp, 6>> bands;
  getTopLevelTileableBands(getOperation(), bands);

  // Tile each band.
  for (auto &band : bands) {
    // Set up tile sizes; fill missing tile sizes at the end with default tile
    // size or tileSize if one was provided.
    SmallVector<unsigned, 6> tileSizes;
    getTileSizes(band, &tileSizes);
    if (llvm::DebugFlag) {
      auto diag = band[0].emitRemark("using tile sizes [");
      llvm::interleaveComma(tileSizes, llvm::dbgs());
      diag << "]\n";
    }
    SmallVector<AffineForOp, 6> tiledNest;
    if (failed(tilePerfectlyNested(band, tileSizes, &tiledNest))) {
      // An empty band always succeeds.
      assert(!band.empty() && "guaranteed to succeed on empty bands");
      LLVM_DEBUG(band.front()->emitRemark("loop tiling failed!\n"));
      continue;
    }

    // Separate full and partial tiles.
    if (separate) {
      auto intraTileLoops =
          MutableArrayRef<AffineForOp>(tiledNest).drop_front(band.size());
      if (failed(separateFullTiles(intraTileLoops))) {
        assert(!intraTileLoops.empty() &&
               "guaranteed to succeed on empty bands");
        LLVM_DEBUG(intraTileLoops.front()->emitRemark(
            "separation post tiling failed!"));
      }
    }
  }
}
