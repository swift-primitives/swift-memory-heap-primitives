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
// Heap-backed allocator integration tests — relocated from swift-memory-allocation-primitives when
// the heap → allocation edge was inverted (allocation must not name the concrete `Memory.Heap`; the
// leaf hosts both the heap-backed conveniences AND their tests). Exercises
// `Memory.Allocator<Memory.Heap>.{System (passthrough), Pool, Arena}`.

import Index_Primitives
import Memory_Allocation_Primitives
import Memory_Heap_Primitives
import Testing

@Suite(.serialized)
struct MemoryAllocatorHeapBackedTests {

    // MARK: - Pool (fixed-slot free list — Bit.Vector double-free, LIFO reuse, typed errors)

    @Suite struct Pool {
        typealias Pool = Memory.Allocator<Memory.Heap>.Pool
        typealias Slot = Memory.Allocator<Memory.Heap>.Pool.Slot

        static func makePool(slotSize: UInt = 16, capacity: Index<Slot>.Count) throws(Pool.Error) -> Pool {
            try Pool(
                slotSize: Memory.Address.Count(UInt(slotSize)),
                slotAlignment: Memory.Alignment.`8`,
                capacity: capacity
            )
        }

        @Test func freshPoolIsEmpty() throws {
            let pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            let cap = pool.capacity
            let alloc = pool.allocated
            let avail = pool.available
            let exhausted = pool.isExhausted
            #expect(cap == Index<Slot>.Count(4))
            #expect(alloc == .zero)
            #expect(avail == Index<Slot>.Count(4))
            #expect(!exhausted)
        }

        @Test func invalidCapacityThrows() {
            var threw = false
            do { _ = try Self.makePool(capacity: Index<Slot>.Count(0)) } catch { if case .invalidCapacity = error { threw = true } }
            #expect(threw)
        }

        @Test func slotSizeTooSmallThrows() {
            var threw = false
            do { _ = try Self.makePool(slotSize: 1, capacity: Index<Slot>.Count(4)) } catch { if case .slotSizeTooSmall = error { threw = true } }
            #expect(threw)
        }

        @Test func allocatedSlotsAreDistinctAndHoldTypedContent() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            var slots: [Index<Slot>] = []
            for i in 0..<4 {
                let slot = try pool.allocateSlot()
                slots.append(slot)
                // Store typed content into the allocated slot (clobbering the in-band free-list bytes —
                // sound precisely because an allocated slot's free-list link is dead).
                unsafe pool.pointer(at: slot).storeBytes(of: 1000 + i, as: Int.self)
            }
            var readback: [Int] = []
            for slot in slots {
                readback.append(unsafe pool.pointer(at: slot).load(as: Int.self))
            }
            #expect(readback == [1000, 1001, 1002, 1003])
            let alloc = pool.allocated
            let avail = pool.available
            let exhausted = pool.isExhausted
            #expect(alloc == Index<Slot>.Count(4))
            #expect(avail == .zero)
            #expect(exhausted)
        }

        @Test func exhaustionThrows() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(2))
            _ = try pool.allocateSlot()
            _ = try pool.allocateSlot()
            var exhaustedCapacity: Index<Slot>.Count? = nil
            do { _ = try pool.allocateSlot() } catch { if case .exhausted(let cap) = error { exhaustedCapacity = cap } }
            #expect(exhaustedCapacity == Index<Slot>.Count(2))
        }

        @Test func freeThenReallocateReusesSlotLIFO() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            let s0 = try pool.allocateSlot()
            let s1 = try pool.allocateSlot()
            let s2 = try pool.allocateSlot()
            _ = s2
            try pool.deallocate(at: s1)  // free list head → s1
            try pool.deallocate(at: s0)  // free list head → s0, s0.next → s1
            let afterFree = pool.allocated
            #expect(afterFree == Index<Slot>.Count(1))
            let r0 = try pool.allocateSlot()  // LIFO: last freed (s0) first
            let r1 = try pool.allocateSlot()  // then s1
            #expect(r0 == s0)
            #expect(r1 == s1)
        }

        @Test func doubleFreeDetectedEvenWithTypedContent() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            let slot = try pool.allocateSlot()
            // Write typed content that overwrites the slot's would-be free-list bytes.
            unsafe pool.pointer(at: slot).storeBytes(of: 0x0BAD_F00D, as: Int.self)
            try pool.deallocate(at: slot)  // first free: succeeds (Bit.Vector cleared)
            var doubleFreed = false
            do { try pool.deallocate(at: slot) }  // second free: Bit.Vector detects it
            catch { if case .doubleFree = error { doubleFreed = true } }
            #expect(doubleFreed)
        }

        @Test func indexForPointerRoundTrips() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            let s0 = try pool.allocateSlot()
            let s1 = try pool.allocateSlot()
            let i0 = unsafe pool.index(for: pool.pointer(at: s0))
            let i1 = unsafe pool.index(for: pool.pointer(at: s1))
            #expect(i0 == s0)
            #expect(i1 == s1)
        }

        @Test func foreignPointerRejected() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            _ = try pool.allocateSlot()
            let foreign = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
            defer { unsafe foreign.deallocate() }
            var rejected = false
            do { unsafe try pool.deallocate(foreign) } catch { if case .foreignPointer = error { rejected = true } }
            #expect(rejected)
        }

        @Test func resetReclaimsAllSlots() throws {
            var pool = try Self.makePool(capacity: Index<Slot>.Count(4))
            _ = try pool.allocateSlot()
            _ = try pool.allocateSlot()
            pool.reset()
            let alloc = pool.allocated
            let avail = pool.available
            let exhausted = pool.isExhausted
            #expect(alloc == .zero)
            #expect(avail == Index<Slot>.Count(4))
            #expect(!exhausted)
            for _ in 0..<4 { _ = try pool.allocateSlot() }
            let reExhausted = pool.isExhausted
            #expect(reExhausted)
        }
    }

    // MARK: - Arena (bump allocator over a Resource region)

    @Suite struct Arena {
        typealias Arena = Memory.Allocator<Memory.Heap>.Arena

        @Test func freshArenaHasFullCapacity() {
            let arena = Arena(byteCount: 1024, alignment: .`8`)
            let cap = arena.capacity
            let alloc = arena.allocated
            #expect(cap.underlying == 1024)
            #expect(alloc.underlying == 0)
        }

        @Test func allocateBumpsTheCursor() throws {
            var arena = Arena(byteCount: 1024, alignment: .`8`)
            _ = try arena.allocate(count: Memory.Address.Count(UInt(100)), alignment: .`8`)
            let alloc = arena.allocated
            #expect(alloc.underlying >= 100)
        }

        @Test func insufficientCapacityThrows() {
            var arena = Arena(byteCount: 16, alignment: .`8`)
            var threw = false
            do { _ = try arena.allocate(count: Memory.Address.Count(UInt(64)), alignment: .`8`) } catch { if case .insufficientCapacity = error { threw = true } }
            #expect(threw)
        }

        @Test func resetReclaimsTheArena() throws {
            var arena = Arena(byteCount: 1024, alignment: .`8`)
            _ = try arena.allocate(count: Memory.Address.Count(UInt(100)), alignment: .`8`)
            arena.reset()
            let alloc = arena.allocated
            #expect(alloc.underlying == 0)
        }
    }

    // MARK: - System (passthrough — the bare allocator forwards the Region seam to its resource)

    @Suite struct System {
        typealias System = Memory.Allocator<Memory.Heap>

        @Test func heapBackedSystemReportsRegionCapacity() {
            let system = System(byteCount: 512, alignment: .`8`)
            let cap = system.capacity
            #expect(cap.underlying == 512)
        }

        @Test func baseForwardsToResourceAndIsStable() {
            let system = System(byteCount: 256, alignment: .`8`)
            let first = system.base
            let second = system.base
            #expect(first == second)
        }
    }
}
