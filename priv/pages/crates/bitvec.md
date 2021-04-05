---
title: bitvec
---

# `bitvec`

[![Crate](https://img.shields.io/crates/v/bitvec.svg "Crate version"){:.unset}](https://crates.io/crates/bitvec "Crate")
[![Documentation](https://docs.rs/bitvec/badge.svg "Crate docs){:.unset}](https://docs.rs/bitvec/ "Documentation")
[![License](https://img.shields.io/crates/l/bitvec.svg "Crate license"){:.unset}](https://github.com/bitvecto-rs/bitvec/blob/develop/LICENSE.txt "License")
[![Downloads](https://img.shields.io/crates/dv/bitvec.svg "Crate downloads"){:.unset}](https://crates.io/crates/bitvec "Crate")
[![Lines of Code](https://tokei.rs/b1/github/bitvecto-rs/bitvec?category=code "Crate size"){:.unset}](https://github.com/bitvecto-rs/bitvec "Repository")

- [Source code](https://github.com/bitvecto-rs/bitvec)

`bitvec` is a Rust implementation of the bit-packing data structure available in
C++ as `std::vector<bool>` and `std::bitset`. In features, API completeness, and
expressiveness, it surpasses every other bit-packing library both in Rust and in
any other language.

It is, to my knowledge, the best-in-class library for working with memory at
single-bit precision. It compiles to the shift-and-mask instructions you would
ordinarily write, while eliminating the need to use anything other than semantic
addresses.

If your work involves bit-level manipulation of memory registers,
partial-register data compaction, bitfields, or large collections of `bool`s,
then you want this library.

## Sample

```rust
use bitvec::prelude::*;

static BITS: &'static BitSlice<Msb0, u16> = bits![Msb0, u8,
  0, 1, 1, 0, 0, 0, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 1, 0, 1, 0, 0,
  0, 1, 1, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 0, 1, 0, 1,
  0, 1, 1, 0, 0, 0, 1, 1,
];

#[repr(C})]
pub struct Magic {
  inner: BitArr!(for 128, in Lsb0, u32),
}

impl Magic {
  fn bitfield(&self) -> &BitSlice<Lsb0, u32> {
    &self.inner[5 .. 30]
  }

  fn bitfield_mut(&mut self) -> &mut BitSlice<Lsb0, u32> {
    &mut self.inner[5 .. 30]
  }

}

fn write(place: &mut Magic, val: u32) {
  place.bitfield_mut().store_le(val);
}

fn read(place: &Magic) -> u32 {
    place.bitfield().load_le()
}
```

## History

I began writing `bitvec` on 2018 Jun 28. I had at the time been working on an
implementation of the Ball Aerospace [COSMOS][cosmos] message definition
language. This language defines bitfields, which in C++ can be written as native
struct or class fields. Rust has no such language element, so I began
implementing it as a library.

Because the COSMOS language allows users to specify both the endianness and
register type of fields, I designed `bitvec` from day one to take both of these
as type parameters. Of the major bitfield implementations, only the C/C++
structural definition is parametric over the register type, and no other
implementation is parametric over bit ordering.

My initial drafts establishing the library foundations were hampered by the
universal flaw common to all bitstream implementations (except Erlang’s):
either the handle is large and slower than the equivalent `[bool]` handle, or it
cannot track the start bit’s position in the head element.

In December, I came up with a solution. Rust is unique among systems languages
in that pointers to sequences have a well-defined representation of carrying
both the address of the first element, and the length of the sequence, as a pair
of processor registers. This corresponds to the C idiom of carrying `void*` and
`size_t` separately. Because Rust guarantees two registers of space for these
pointers, rather than one, and I only need three bits to encode the location of
the start bit in the first byte, I could pack the start bit into the pointer’s
representation, and use `*const BitSlice` rather than `struct BitSlicePtr` to
describe *any* region of memory as a [`BitSlice`].

> I am obligated to mention here that Rust only specifies that slice pointers
> are two words in size. It does *not* guarantee precise layout. The
> transformation `mem::transmute::<*const [u8], (*const u8, usize)>` is **not**
> guaranteed to be correct.
> {:.iso7010 .p029}
>
> Rust provides the APIs [`core::ptr::slice_from_raw_parts`][p_sfrp],
> [`<*const slice<T>>::as_ptr`][sp_as_ptr], and
> [`<*const slice<T>>::len`][sp_len], which `bitvec` uses for all conversion
> between the opaque slice pointer type and its own internal data structures.
> {:.iso7010 .p010}
>
> > Not being able to write `[T]` inside a Markdown link text is an infuriating
> > limitation.
>
> You must **never** attempt to view the contents of a Rust or `bitvec` region
> pointer except through the provided de/composing APIs. While these layouts are
> guaranteed at the machine level, they are *not* guaranteed at the source
> level, and both the standard library and I reserve the right to modify the
> layout at any time without causing an API breaking change.
> {:.iso7010 .p015}
{:.bq-harm}

Once I established an encoding of element address, starting bit, and bit count
into a standard Rust slice pointer, I was able to use the full idiomatic API and
expectations of the Rust language without limitation. This encoding is unique in
Rust crates to `bitvec`, and by enabling the construction of `&BitSlice`
references, it unlocks full, seamless, access to APIs that demand reference
types rather than mere borrowing handles. `BitSlice` is indexable with the `[]`
operator; no other Rust library can provide this.

Since 2018 Dec, I have continued development by reïmplementing the full standard
library APIs for `[bool]` regions, `[bool; N]` arrays, `Box<[N]>` owned slices,
and `Vec<bool>` vectors. I have also implemented bitfield register storage in
the library, enabling users to write `bits[span].load_or_store()` to move
register values into and out of a `BitSlice` region, equivalent to C member
bitfields.

`bitvec` is now feature-complete, and I intend to publish `1.0` and switch to
maintenance-only on 2021 Jun 28.

## Type Parameters

In addition to the pointer encoding scheme, `bitvec` is unique in its use of the
Rust trait system to allow users to select the register element type and the
translation of semantic indices to electrical positions. In fact, `bitvec`
permits users to supply their own ordering implementations, and the rest of the
library will seamlessly work with them.

The [`BitStore`] trait defines `bitvec`’s interface to memory. It is implemented
on plain register integers, their `Cell<>` wrappers, and their `Atomic`
variants. It is the latter two implementations that allow `bitvec` to safely
express any view of memory, including partitioning a single element across
multiple `&mut BitSlice`s, without violating any of Rust’s rules about data
races.

The [`BitOrder`] trait translates the semantic indices available to users to the
electrical positions used to drive memory. This allows users to only track
abstract numbers, and let their choice of implementation handle producing the
shift/mask or single-bit instructions at the processor level. `bitvec` provides
two out of the box: [`Lsb0`], which places 0 at the least significant bit of a
register and counts to the left, and [`Msb0`], which places `0` at the most
significant bit and counts to the right.

> Read the documentation for `BitOrder` carefully, as well as the associated
> tables showing how `BitOrder` and `BitStore` intersect to control memory
> layouts, before writing any code that relies on memory representation! This is
> a powerful tool that can and will surprise you painfully once you try anything
> other than `<Msb0, u8>`.
{:.bq-info .iso7010 .m002}

## Conveniences

`bitvec` provides constructor macros, similar to the standard library’s `vec!`,
to build up `BitSlice` buffers at compile time. The `bits!` macro accepts any
number of compile- or run- time expressions and uses them to construct the
appropriate buffer. When invoked with literals, `const`s, or values that LLVM
can const-fold, it runs entirely at compile-time and produces a memory buffer
loaded into your `.rodata` section that can be read directly at runtime without
any additional computation.

`bits!` is written entirely by [Nika Layzell], whose advice and expertise on
alias safety and `macro_rules!` has been invaluable in making `bitvec` what it
is today.

The `bitarr!`, `bitbox!`, and `bitvec!` macros build atop `bits!` to create the
desired data structure with the given contents.

## Performance

Rust is still developing its type-level-integer (`const`-generics) capability,
so currently, `bitvec` is not able to use `const` functionality *at all*. Rust
does not allow generics in const contexts, nor does it allow computation at the
type level. These restrictions prevent [`BitArray`] from having the same
signature and precision as C++’s `std::bitset<N>`, and the rest of the crate
from being usable in `static` or `const` contexts.

However, because `BitOrder` is strictly numeric, and the rest of the crate is
built atop it, LLVM is able to perform aggressive const-folding during
compilation. One of my difficulties in observing `bitvec`’s codegen or in
benchmarking its performance has been obfuscating enough to prevent LLVM from
solving it entirely during compilation.

In general, indexing with literal numbers should be completely free, and
indexing with runtime values should be equivalent to the shift/mask instructions
you would be writing without this library. I have not observed the fact that
`&BitSlice` can have unrestricted start positions to have any performance
penalty; accessing the offset is typically only two instructions.

Additionally, thanks to a great deal of work in early 2020, `bitvec` is able to
balance perfect thread-safety with atomic bypass to maintain fast access to
memory that it can observe is not aliased.

## API Completeness

`bitvec` implements *every* part of the standard library APIs for pointers,
references, slices, arrays, boxed slices, and vectors of `[bool]`. The only
items missing at the type level are implementations of
`IndexMut<Target = bool>`, because this trait requires producing `&mut bool`
references (which must be to a full byte, uniquely accessed) rather than a
proxy structure like C++’s `std::bitset::reference`.

`bitvec` provides a `BitPtr` structure that acts like a `*bool`, except that it
points into a `BitSlice` region.

As the standard library grows and evolves, `bitvec` will mirror it.

## Support

> While my other libraries are released as curiosities and a best-effort quality
> basis, I am committed to maintaining `bitvec` to the best extent of my
> capabilities and resources for all users. Please feel free to contact me for
> any reason about your use of it, including bug reports, feature requests, and
> general usage questions.
>
> While this is a hobby project, it is one that I take extremely seriously. I
> cannot guarantee full-time responsiveness, as I am not paid for work on it,
> but I will always do my best to ensure quality and provide active support.
{:.bq-safe .iso7010 .e004}

[`BitArray`]: https://docs.rs/bitvec/latest/bitvec/array/struct.BitArray.html
[`BitOrder`]: https://docs.rs/bitvec/latest/bitvec/order/trait.BitOrder.html
[`BitSlice`]: https://docs.rs/bitvec/latest/bitvec/slice/struct.BitSlice.html
[`BitStore`]: https://docs.rs/bitvec/latest/bitvec/store/trait.BitStore.html
[`Lsb0`]: https://docs.rs/bitvec/latest/bitvec/order/struct.Lsb0.html
[`Msb0`]: https://docs.rs/bitvec/latest/bitvec/order/struct.Msb0.html
[Nika Layzell]: https://github.com/mystor
[cosmos]: https://cosmosrb.com
[p_sfrp]: https://doc.rust-lang.org/core/ptr/fn.slice_from_raw_parts.html
[sp_as_ptr]: https://doc.rust-lang.org/std/primitive.ptr.html#method.as_ptr
[sp_len]: https://doc.rust-lang.org/std/primitive.ptr.html#method.len
