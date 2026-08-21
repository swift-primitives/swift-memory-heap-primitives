public import Memory_Address_Primitives
public import Memory_Primitive

extension Memory.Heap {

    @unsafe
    @inlinable
    public consuming func take() -> (base: UnsafeMutableRawPointer, capacity: Memory.Address.Count)
    {

        let result = unsafe (_base, _capacity)
        discard self
        return unsafe result
    }

    @unsafe
    @inlinable
    public var unsafeBaseAddress: UnsafeRawPointer {

        unsafe UnsafeRawPointer(_base)
    }

    @unsafe
    @inlinable
    public borrowing func withUnsafeBytes<R: ~Copyable, E: Swift.Error>(
        _ body: (UnsafeRawBufferPointer) throws(E) -> R
    ) throws(E) -> R {

        try unsafe body(
            unsafe UnsafeRawBufferPointer(start: _base, count: Int(bitPattern: _capacity))
        )
    }
}
