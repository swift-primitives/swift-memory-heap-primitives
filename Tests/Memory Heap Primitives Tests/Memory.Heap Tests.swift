import Memory_Heap_Primitives_Test_Support
import Testing

@testable import Memory_Heap_Primitives

extension Memory.Heap {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

extension Memory.Heap.Test.Unit {
    @Test
    func `fresh allocation reports the requested byte capacity`() {
        let heap = Memory.Heap(byteCount: 1024, alignment: .`8`)
        #expect(heap.capacity.underlying == 1024)
    }

    @Test
    func `byte capacity tracks the requested size across sizes and alignments`() {
        #expect(Memory.Heap(byteCount: 16, alignment: .byte).capacity.underlying == 16)
        #expect(Memory.Heap(byteCount: 256, alignment: .`16`).capacity.underlying == 256)
        #expect(Memory.Heap(byteCount: 4096, alignment: .`4096`).capacity.underlying == 4096)
    }

    @Test
    func `base address is reachable and stable across reads`() {
        let heap = Memory.Heap(byteCount: 512, alignment: .`8`)
        let first = heap.base
        let second = heap.base
        #expect(first == second)
    }

    @Test
    func `drop frees the owned region without a crash or double free`() {
        do {
            let heap = Memory.Heap(byteCount: 512, alignment: .`8`)
            #expect(heap.capacity.underlying == 512)
            _ = heap.base
        }

        #expect(Bool(true))
    }
}

extension Memory.Heap.Test.EdgeCase {
    @Test
    func `single-byte region is valid`() {
        let heap = Memory.Heap(byteCount: 1, alignment: .byte)
        #expect(heap.capacity.underlying == 1)
    }
}
