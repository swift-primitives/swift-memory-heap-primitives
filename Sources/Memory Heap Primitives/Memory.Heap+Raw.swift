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

// MARK: - Raw egress (the `@unsafe` escape hatches over the REAL origin pointer)
//
// `Memory.Heap` stays `@safe` with `_base` internal (the absorber per [MEM-SAFE-021]); this surface
// adds the deliberate `@unsafe` escape hatches an owning consumer (e.g. `String`/`Path`, which own a
// raw byte region and provide their OWN typed view + raw hand-off) needs. EVERY door here returns /
// exposes the REAL origin pointer `_base` — NEVER a pointer reconstituted from the integer
// `Memory.Address` ([MEM-OWN-015] / [MEM-SAFE-029] / [MEM-SAFE-031]). `take()` is the consuming
// egress (caller assumes the exactly-once free); the borrowed accessors are reads scoped to `self`.

extension Memory.Heap {
    /// Transfers ownership of the underlying region out to the caller.
    ///
    /// Returns the **real, provenance-carrying origin pointer** `_base` and the byte capacity, and
    /// `discard`s `self` so `deinit` does NOT free — the caller (or the next adopter) assumes the
    /// exactly-once free of the origin allocation. Mirrors `String.take()` / `Memory.Foreign.take()`.
    ///
    /// - Returns: A pair of `(base, capacity)` where `base` is the origin pointer (intact provenance,
    ///   safe to `deallocate`) and `capacity` is the region's byte capacity.
    @unsafe
    @inlinable
    public consuming func take() -> (base: UnsafeMutableRawPointer, capacity: Memory.Address.Count) {
        // SAFETY: [MEM-SAFE-031](a) — hands out the origin pointer `_base` (intact provenance), not a
        // SAFETY: pointer reconstituted from an integer address ([MEM-OWN-015]/[MEM-SAFE-029]). `discard
        // SAFETY: self` suppresses the deinit's free so ownership transfers exactly once to the caller;
        // SAFETY: `_base`/`_capacity` are trivially-destroyed, so `discard self` is legal here.
        let result = unsafe (_base, _capacity)
        discard self
        return unsafe result
    }

    /// The base address of the owned region as a raw pointer — a deliberate escape hatch.
    ///
    /// Exposes the **real origin pointer** `_base`. The pointer is only valid for the lifetime of
    /// `self`; sharing it independently of the `Memory.Heap` owner is unsafe and unsupported. Provided
    /// for the property-style raw-base needs of owning consumers (`String.unsafeBaseAddress`); reads
    /// that do not need an escaping pointer should prefer the closure-scoped ``withUnsafeBytes(_:)``
    /// per [MEM-SAFE-014].
    @unsafe
    @inlinable
    public var unsafeBaseAddress: UnsafeRawPointer {
        // SAFETY: returns the REAL origin pointer `_base` (intact provenance), never a pointer
        // SAFETY: reconstituted from `base: Memory.Address` ([MEM-OWN-015]/[MEM-SAFE-029]). Valid for
        // SAFETY: the lifetime of `self`, which uniquely owns the allocation ([MEM-SAFE-031](a)).
        unsafe UnsafeRawPointer(_base)
    }

    /// Invokes `body` with a borrowed raw view of the region, scoped to the call.
    ///
    /// The pointer does not escape the closure ([MEM-SAFE-014]); it is derived from the **real origin
    /// pointer** `_base`, never reconstituted from the integer address. This is the preferred read
    /// surface for owning consumers that reinterpret the bytes (e.g. `String.withUnsafeBufferPointer`).
    @unsafe
    @inlinable
    public borrowing func withUnsafeBytes<R: ~Copyable, E: Swift.Error>(
        _ body: (UnsafeRawBufferPointer) throws(E) -> R
    ) throws(E) -> R {
        // SAFETY: the buffer is built from the REAL origin pointer `_base` + `_capacity` (intact
        // SAFETY: provenance, [MEM-OWN-015]/[MEM-SAFE-029]); the pointer is confined to `body` and does
        // SAFETY: not escape ([MEM-SAFE-014]). `self` is borrowed for the duration, so `_base` is valid.
        try unsafe body(
            unsafe UnsafeRawBufferPointer(start: _base, count: Int(bitPattern: _capacity))
        )
    }
}
