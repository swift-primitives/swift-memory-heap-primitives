public import Memory_Address_Primitives
public import Memory_Primitive

extension Memory {

    @frozen
    @safe
    public struct Heap: ~Copyable {

        @usableFromInline
        internal let _base: UnsafeMutableRawPointer

        @usableFromInline
        internal let _capacity: Memory.Address.Count

        @inlinable
        public init(adopting base: UnsafeMutableRawPointer, capacity: Memory.Address.Count) {
            unsafe self._base = base
            self._capacity = capacity
        }

        @inlinable
        deinit {

            unsafe _base.deallocate()
        }
    }
}
