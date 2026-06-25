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
// The heap-backed pool runs the L1–L5 pool laws — relocated from
// swift-memory-allocation-primitives with the heap → allocation edge inversion. The generic
// `Memory.Pool.Laws` harness stays in allocation-primitives (Test Support product, driven through
// `Memory.Pooling`'s witnesses — the protocol-bound dispatch is itself under test); the concrete
// heap conformer that feeds it lives here, with the leaf.

import Index_Primitives
import Memory_Allocation_Primitives
import Memory_Allocation_Primitives_Test_Support
import Memory_Heap_Primitives
import Testing

@Suite
struct MemoryPoolLawHeapTests {
    @Test
    func `the heap pool obeys the pool laws L1-L5`() {
        let violations = Memory.Pool.Laws.violations(
            makePool: {
                // WHY: slotSize ≥ the in-band link size and capacity > 0 → the
                // validating init never throws.
                // swift-format-ignore: NeverUseForceTry
                // swiftlint:disable:next force_try
                try! Memory.Allocator<Memory.Heap>.Pool(
                    slotSize: Memory.Address.Count(UInt(MemoryLayout<Int>.stride)),
                    slotAlignment: .`8`,
                    capacity: Index<Memory.Pool.Slot>.Count(UInt(4))
                )
            },
            expectedCapacity: 4
        )
        #expect(violations.isEmpty, "\(violations)")
    }
}
