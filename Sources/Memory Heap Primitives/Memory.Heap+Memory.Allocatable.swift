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

public import Memory_Allocator_Protocol_Primitives

// MARK: - Memory.Allocatable (adopt-role) + Memory.Growable (fresh byte-construction)

/// `Memory.Heap` adopts both element-free allocation seams. As a `Memory.Allocatable` it can be
/// wrapped as a passthrough `Memory.Allocator<Memory.Heap>` (the default `makeAllocator()` adopts the
/// whole owned region). As a `Memory.Growable` it can be allocated fresh to a byte count — the
/// `init(byteCount:alignment:)` in `Memory.Heap ~Copyable.swift` is exactly that requirement, so the
/// conformance is satisfied by the existing initializer.
///
/// These are the post-inversion conformances the leaf declares now that the edge points
/// heap → allocation (`Memory.Allocatable` adopt-role + `Memory.Growable` fresh-construction).
extension Memory.Heap: Memory.Allocatable {}

extension Memory.Heap: Memory.Growable {}
