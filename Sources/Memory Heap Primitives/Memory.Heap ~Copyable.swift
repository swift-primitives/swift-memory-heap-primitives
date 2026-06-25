// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Memory_Address_Primitives
public import Memory_Alignment_Primitives
public import Memory_Primitive
public import Memory_Primitives_Standard_Library_Integration
public import Memory_Region_Primitives

// MARK: - Fresh allocation

extension Memory.Heap {
    /// Allocates a fresh, self-owning heap region of `byteCount` bytes at `alignment`.
    @inlinable
    public init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {
        // SAFETY: [MEM-SAFE-031](a) permanent allocation floor — `allocate` returns the real,
        // SAFETY: provenance-carrying origin pointer; `Memory.Heap` adopts it directly and frees
        // SAFETY: through it on `deinit`. No `Memory.Address` round-trip ([MEM-OWN-015]).
        let raw = unsafe UnsafeMutableRawPointer.allocate(count: byteCount, alignment: alignment)
        unsafe self.init(adopting: raw, capacity: byteCount)
    }
}

// MARK: - Region (element-free raw-region seam)

extension Memory.Heap: Memory.Region {
    /// The stable base address of the region's first byte.
    @inlinable
    public var base: Memory.Address {
        // SAFETY: derived seam value only — `Memory.Address` is an integer that carries no provenance.
        // SAFETY: Computed per access from the cached origin pointer `_base` (valid for the lifetime of
        // SAFETY: `self`, which owns the allocation); the region is freed through `_base`, never through
        // SAFETY: a pointer reconstituted from this address ([MEM-OWN-015]/[MEM-SAFE-029]). [MEM-SAFE-025a]
        unsafe Memory.Address(_base)
    }

    /// The region's capacity in bytes.
    @inlinable
    public var capacity: Memory.Address.Count {
        _capacity
    }
}

// MARK: - Sendable

/// ## Safety Invariant
///
/// Category B — ownership transfer. `Memory.Heap` is a move-only owning absorber over a raw byte
/// region (its origin `UnsafeMutableRawPointer` + byte capacity); unique `~Copyable` ownership means
/// only one thread can hold it at a time, and cross-thread transfer is a move that relinquishes the
/// sender's access. Per [MEM-SAFE-024] the conformance clause carries bare `@unchecked Sendable`
/// (thread-safety claim only); the type encapsulates its raw storage behind a safe API and is marked
/// `@safe` per [MEM-SAFE-021], so the memory-safety dimension never reaches this clause.
extension Memory.Heap: @unchecked Sendable {}
