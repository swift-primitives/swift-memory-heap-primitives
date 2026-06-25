# ``Memory_Heap_Primitives``

@Metadata {
    @DisplayName("Memory Heap Primitives")
    @TitleHeading("Swift Primitives")
}

A single owned, heap-allocated raw byte region. `Memory.Heap` owns a move-only block of bytes, frees it exactly once on destruction, and exposes it as a `base` address plus a byte `capacity` — the element-free leaf an allocator carves typed storage from.

## Topics

### The heap region

- ``Memory/Heap``
```
