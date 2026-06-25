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
public import Memory_Primitive

extension Memory {
    /// The element-free heap leaf — a single owned raw byte region.
    ///
    /// In the prior shape `Memory.Heap<Element>` was a typed `ManagedBuffer`-backed façade that
    /// carried the `Store.Initialization` ledger and the cleanup-oracle `deinit`. The five-layer
    /// tower makes Memory **element-free**: `Memory.Heap` now owns only raw bytes — the
    /// **real, provenance-carrying origin pointer** returned by `allocate` plus its byte capacity —
    /// and conforms the `Memory.Region` seam (`base` + `capacity`) so an allocator can carve within
    /// it. The ledger + cleanup oracle move UP to the Storage tier (where `Element` enters). The
    /// leaf is unconditionally `~Copyable`; its `deinit` deallocates the origin pointer exactly once.
    ///
    /// ## Provenance is load-bearing
    ///
    /// The leaf stores the origin `UnsafeMutableRawPointer` and frees through **that** pointer; it
    /// MUST NOT store an integer `Memory.Address` and reconstitute a pointer in `deinit` to free
    /// (forbidden by [MEM-OWN-015] / [MEM-SAFE-029] / [MEM-SAFE-031] — a reconstituted pointer carries
    /// no provenance, so the optimizer may assume non-aliasing, `deallocate` is no longer guaranteed
    /// to act on the origin allocation, and PAC/MTE metadata is stripped). `base` is a *derived* seam
    /// value (`Memory.Address` — an integer that carries no provenance), computed per access from the
    /// cached origin pointer, never the thing the region is freed through.
    ///
    /// The cached origin pointer is the permanent allocation floor per [MEM-SAFE-031](a): lawful here
    /// because `Memory.Heap` IS the concrete heap-pinned path [MEM-SAFE-029] sanctions for a cached
    /// base — it is not derived in generic code.
    ///
    /// Region conformance, the fresh-allocation initializer, and `Sendable` live in
    /// `Memory.Heap ~Copyable.swift`.
    ///
    /// ## Safety Invariant
    ///
    /// Category D (SP-5) — pointer-backed value-like leaf. `_base` is the origin
    /// `UnsafeMutableRawPointer` from `allocate`, set once and never reassigned; the public API
    /// (`base` / `capacity` / the adopt + fresh-allocation inits) never hands the raw pointer out, so
    /// callers use the whole surface without writing `unsafe`. Unique `~Copyable` ownership makes the
    /// current owner the only reader; `deinit` frees through `_base` exactly once. The cached base is
    /// lawful here because `Memory.Heap` is the concrete heap-pinned path [MEM-SAFE-029] sanctions
    /// ([MEM-SAFE-021], [MEM-SAFE-025b]/[MEM-SAFE-025c], [MEM-SAFE-031]).
    ///
    /// ## Layout note
    ///
    /// `@frozen` per [API-IMPL-022] (tower value types ship `@frozen` from birth): the cross-module
    /// consuming decomposition `take()` performs (`Memory.Heap+Raw.swift`) is illegal without it. Both
    /// stored fields are trivially-destroyed, so `take()` uses a direct `discard self` (no guarded
    /// finalizer — the `Memory.Foreign` / `Completion.Entry` Optional-finalizer workaround is for
    /// closure-bearing storage, which this leaf has none of).
    @frozen
    @safe
    public struct Heap: ~Copyable {
        // SAFETY: [MEM-SAFE-031](a) permanent allocation floor — set once at init from `allocate`
        // SAFETY: and never reassigned; valid for the whole lifetime of `self`, which uniquely owns
        // SAFETY: the allocation. Caching the real base here is lawful per [MEM-SAFE-029] because
        // SAFETY: `Memory.Heap` is the concrete heap-pinned path (not generic code). Freed exactly
        // SAFETY: once in `deinit` through this same origin pointer (move-only ⇒ single free).
        /// The owned region's real, provenance-carrying origin pointer — the value returned by
        /// `allocate` and the value `deinit` frees through.
        ///
        /// Never reconstituted from `base`.
        @usableFromInline
        internal let _base: UnsafeMutableRawPointer

        /// The region's capacity in bytes.
        @usableFromInline
        internal let _capacity: Memory.Address.Count

        /// Adopts an existing, allocated raw byte region by its origin pointer and byte capacity.
        ///
        /// The caller transfers ownership: after this call `Memory.Heap` owns the region and frees it
        /// through `base` on `deinit`. The caller MUST NOT use or deallocate `base` afterwards, and
        /// `base` MUST be the origin pointer returned by the allocation (so its provenance is intact).
        @inlinable
        public init(adopting base: UnsafeMutableRawPointer, capacity: Memory.Address.Count) {
            unsafe self._base = base
            self._capacity = capacity
        }

        @inlinable
        deinit {
            // SAFETY: [MEM-SAFE-031](a) — frees through the origin pointer `_base` (intact provenance),
            // SAFETY: not a pointer reconstituted from an integer address ([MEM-OWN-015]/[MEM-SAFE-029]).
            // SAFETY: `_base` is set once at init and `Heap` is move-only, so this is the single free.
            unsafe _base.deallocate()
        }
    }
}
