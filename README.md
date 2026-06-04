# swift-memory-heap-primitives

`Memory.Heap<Element>` — the heap allocation-strategy leaf: a `~Copyable` value façade over a single `ManagedBuffer` allocation whose backing-class `deinit` is the cleanup oracle for its `Store.Initialization` ledger. Created by the storage/memory split (swift-institute/Research/storage-memory-split.md, seat-ratified 2026-06-04); `Storage<E>.Heap` becomes a typealias for `Storage<E>.Contiguous<Memory.Heap<E>>`.
