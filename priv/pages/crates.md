---
title: Crates by myrrlyn
---

# Crates

This is a summary of Rust projects I have written.

## `bitvec`

[More details](/crates/bitvec)

`bitvec` is a version of the Rust linear-sequence collections (`[bool]`,
`[bool; N]`, and `Vec<bool>`) that applies a single-bit-storage optimization to
ensure that the memory usage of each `bool` in the collection is exactly one bit
rather than eight.

Unlike any of its peers in other languages, such as C++ `std::vector<bool>`, it
permits users to select the exact memory representation they need, enabling it
to not only drive memory-compacted collections of `bool` but also to serve as
the basis for universally-applicable, exactly-representable, bitfield locations
for any integral value.

Furthermore, `bitvec` is unique among Rust bit-packing libraries in that it is
able to use `&BitSlice` references to exactly match the standard idioms and APIs
that demand *references* to a memory region, rather than *handles* to it. This
functionality allows `bitvec` to be drop-in compatible with existing code, with
only one exception.

## `tap`

[More details](/crates/tap)

`tap` provides three utility traits that exist as base-object methods or
language features elsewhere:

- `Tap` allows you to transparently inspect a value without changing its type;
  this is useful for attaching tracepoints to a data pipeline with minimal
  disruption to surrounding code, or applying modify-in-place methods to a value
  without needing to `let`-bind it twice,
- `Pipe` allows you to place any function call in suffix position, including
  functions that change the type. It is equivalent to the `|>` operator in F♯,
  or D’s universal suffix-call syntax.
- `Conv` allows you to replace `.into()`, which cannot specify the destination
  type, with `.conv::<T>()`, which can.

## `calm_io`

[More details](/crates/calm_io)

`calm_io` suppresses expected I/O error events that the user expects to occur
during ordinary operation, so that those particular I/O failures do not cause
user-facing panics.

This was motivated by the discovery that Unix pipelines deliver `SIGPIPE` to
the program holding one half of a pipe when the program holding the other half
closes it. The default C runtime terminates upon delivery, while the default
Rust runtime ignores it, so Rust programs that attempt to operate on a
now-closed pipe receive `-EPIPE` as the error code, and panic.

`calm_io` provides replacement I/O macros that bubble errors instead of
unwrapping them, and decorator macros for `main` that detect
`io::ErrorKind::BrokenPipe` and translate it into a graceful shutdown instead of
a crash.

## `wyz`

[More details](/crates/wyz)

This is my general-purpose utility library. It contains little snippets of code
I think are worth reüsing, but are not yet worth publishing as standalone
crates.

## `lilliput`

[More details](/crates/lilliput)

This project performs endian-reördering in-place, so that de/serialization code
does not have to be configured to do so. It also provides macros that allow
aggregates of reörderable types to be themselves reörderable, so that users do
not have to descend to each leaf integer and flip it as part of
de/serialization.

[More details](/crates/lilliput)
