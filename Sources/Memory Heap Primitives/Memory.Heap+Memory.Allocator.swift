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
//
// The heap-backed allocator construction conveniences — moved down from
// swift-memory-allocation-primitives (which, post dependency-inversion, must not name a concrete
// leaf). The generic `Memory.Allocator<Resource>` / `.Arena` / `.Pool` strategies live in
// allocation-primitives; the `where Resource == Memory.Heap` sugar that allocates a fresh heap region
// lives here, with the leaf it names.

import Affine_Discrete_Primitives
import Affine_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Memory_Address_Primitives
public import Memory_Alignment_Primitives
public import Memory_Allocator_Arena_Primitives
public import Memory_Allocator_Pool_Primitives
public import Memory_Allocator_Primitive
public import Memory_Primitive

// MARK: - Passthrough (Resource == Memory.Heap)

extension Memory.Allocator where Resource == Memory.Heap {
    /// Allocates a fresh heap region of `byteCount` bytes and wraps it as a passthrough allocator.
    @inlinable
    public init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {
        self.init(Memory.Heap(byteCount: byteCount, alignment: alignment))
    }
}

// MARK: - Arena (Resource == Memory.Heap)

extension Memory.Allocator.Arena where Resource == Memory.Heap {
    /// Creates a bump arena over a fresh, self-owning heap region of `byteCount` bytes.
    @inlinable
    public init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {
        self.init(Memory.Heap(byteCount: byteCount, alignment: alignment))
    }
}

// MARK: - Pool (Resource == Memory.Heap)

extension Memory.Allocator.Pool where Resource == Memory.Heap {
    /// Creates a pool with the specified slot geometry and capacity over a fresh heap region.
    ///
    /// All slots start uninitialized. O(1) virgin-cursor initialization (no free list pre-build).
    /// The pool allocates and owns a `Memory.Heap` of exactly `capacity * slotStride` bytes.
    @inlinable
    public init(
        slotSize: Memory.Address.Count,
        slotAlignment: Memory.Alignment,
        capacity: Index<Slot>.Count
    ) throws(Error) {
        // The heap-backed pool is the region-carving pool over a freshly allocated, exactly-sized heap
        // region: allocate `capacity * slotStride` bytes, then carve. Delegating to the generic public
        // `init(carving:slotSize:slotAlignment:)` keeps the slot-geometry validation (slot-size floor,
        // capacity > 0) in one place — the validation that the private designated init (package-internal
        // to allocation-primitives, unreachable here) used to inline.
        let slotStride = Affine.Discrete.Ratio<Slot, Memory>(slotAlignment.align.up(slotSize))
        let byteCount = capacity * slotStride
        try self.init(
            carving: Memory.Heap(byteCount: byteCount, alignment: slotAlignment),
            slotSize: slotSize,
            slotAlignment: slotAlignment
        )
    }
}
