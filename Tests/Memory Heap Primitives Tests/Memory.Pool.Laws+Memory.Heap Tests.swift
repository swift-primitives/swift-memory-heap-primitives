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
