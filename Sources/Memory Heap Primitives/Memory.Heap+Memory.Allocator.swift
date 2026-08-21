import Affine_Discrete_Primitives
import Affine_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Memory_Address_Primitives
public import Memory_Alignment_Primitives
public import Memory_Allocator_Arena_Primitives
public import Memory_Allocator_Pool_Primitives
public import Memory_Allocator_Primitive
public import Memory_Primitive

extension Memory.Allocator where Resource == Memory.Heap {

    @inlinable
    public init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {
        self.init(Memory.Heap(byteCount: byteCount, alignment: alignment))
    }
}

extension Memory.Allocator.Arena where Resource == Memory.Heap {

    @inlinable
    public init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {
        self.init(Memory.Heap(byteCount: byteCount, alignment: alignment))
    }
}

extension Memory.Allocator.Pool where Resource == Memory.Heap {

    @inlinable
    public init(
        slotSize: Memory.Address.Count,
        slotAlignment: Memory.Alignment,
        capacity: Index<Slot>.Count
    ) throws(Error) {

        let slotStride = Affine.Discrete.Ratio<Slot, Memory>(slotAlignment.align.up(slotSize))
        let byteCount = capacity * slotStride
        try self.init(
            carving: Memory.Heap(byteCount: byteCount, alignment: slotAlignment),
            slotSize: slotSize,
            slotAlignment: slotAlignment
        )
    }
}
