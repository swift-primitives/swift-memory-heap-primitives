# Memory Heap Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-memory-heap-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-memory-heap-primitives/actions/workflows/ci.yml)

`Memory.Heap` — a single owned, heap-allocated raw byte region. It holds a move-only block of uninitialized bytes and frees that block exactly once, when the value is destroyed. There is no element type and no initialization bookkeeping: a `Heap` is raw heap memory and nothing else, exposed as a `base` address plus a byte `capacity` — the shape an allocator carves typed storage out of.

Because the backing block is move-only and owns its allocation, destruction frees the region exactly once — there is no reference counting and no `deinit` to write or get wrong. Typed element storage, the initialization ledger, and element teardown live one tier up, at the Storage layer; the heap leaf stays element-free.

---

## Key Features

- **Single-free by construction** — the region is move-only and owns its allocation; destroying the value frees the bytes exactly once, with no `deinit` to author and no double-free to guard against.
- **Element-free** — raw bytes, no `Element` parameter, no initialization ledger; typing is added by the allocator and storage tiers above.
- **Carve-ready** — exposes a memory region (`base` + `capacity`), so an allocator can sub-allocate typed slots within it.
- **`~Copyable`** — the owned allocation is never implicitly duplicated.

---

## Quick Start

```swift
import Memory_Heap_Primitives

// A heap-allocated block of raw bytes, owned and freed exactly once.
let region = Memory.Heap(byteCount: byteCount, alignment: alignment)

// `region` is a memory region — a `base` address and a byte `capacity`.
// An allocator carves typed slots within it; when `region` is destroyed its
// bytes are freed once, with no `deinit` to write and no double-free to guard.
```

A `Heap` may also adopt an existing self-owning raw byte region (`Memory.Heap(adopting:)`) rather than allocating a fresh one.

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Memory Heap Primitives` | `Memory.Heap` — the owned raw byte region, its memory-region conformance, and the allocating / adopting initializers | The only product — import this |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-memory-primitives`](https://github.com/swift-primitives/swift-memory-primitives) — `Memory.Region`, the region seam a `Heap` exposes.
- [`swift-memory-allocation-primitives`](https://github.com/swift-primitives/swift-memory-allocation-primitives) — the allocators (pool, arena, system) that carve typed slots within a `Heap`.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
