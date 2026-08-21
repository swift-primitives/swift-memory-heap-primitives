public import Memory_Address_Primitives
public import Memory_Alignment_Primitives
public import Memory_Primitive
public import Memory_Primitives_Standard_Library_Integration
public import Memory_Region_Primitives

extension Memory.Heap {

    @inlinable
    public init(byteCount: Memory.Address.Count, alignment: Memory.Alignment) {

        let raw = unsafe UnsafeMutableRawPointer.allocate(count: byteCount, alignment: alignment)
        unsafe self.init(adopting: raw, capacity: byteCount)
    }
}

extension Memory.Heap: Memory.Region {

    @inlinable
    public var base: Memory.Address {

        unsafe Memory.Address(_base)
    }

    @inlinable
    public var capacity: Memory.Address.Count {
        _capacity
    }
}

extension Memory.Heap: @unchecked Sendable {}
