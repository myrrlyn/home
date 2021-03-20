---
title: ~/text.css
---

This page contains sample text of various styled elements that appear on the
site, in order to provide quick visual testing of the overall theme.

# Title

## Chapter

### Section

#### Subsection

##### Heading

###### Subheading

> This is an ordinary blockquote with no semantic information attached.
>
> > Rack em

<!-- -->

> This is a danger blockquote.
>
> > It even has a second danger blockquote!
> {:.bq-danger .iso7010 .p015}
{:.bq-danger .iso7010 .p010}

<!-- -->

> This is a warning blockquote.
>
> > Mixing class indicators is bad, actually
> {:.bq-danger .iso7010 .p025}
{:.bq-warn .iso7010 .w027}

<!-- -->

> This is a safety blockquote.
>
> > Stack em
{:.bq-safe .iso7010 .e003}

<!-- -->

> This is an informational blockquote.
>
> > Call me a bird
> {: .iso7010 .m001}
> > because I love bulding nests
> {: .iso7010 .m005}
{:.bq-info .iso7010 .m002}

This is **bold**, *italic*, and `inline code` text.

```rust
#[repr(C)]
pub struct BitSpan<O, T>
where O: BitOrder, T: BitStore {
  ptr: NonNull<u8>,
  len: usize,
}

impl<O, T> BitSpan<O, T>
where O: BitOrder, T: BitStore {
  /// Constructor
  pub fn new(
    addr: *mut T,
    head: BitIdx<T::Mem>,
    bits: usize,
  ) -> Result<Self, Error> {
    todo!("Draw the rest of the owl")
  }
}
```

```text
This block is ordinary text and
should never be syntax highlit.

This is a really quite egregiously long line that probably looks ugly on mobile.
```

```sh
cat ./demo.txt
curl https://sh.rustup.rs | pv | sh -- -s
# this is a shell script
```

Here is a `long run of inline code` {:.other} just to see it in the AST.

- Lists
  - of lists
    - of lists
- are uninteresting
  - when bullets
    - don’t change

1. Numbered lists
   1. and sublists
      1. and sublists
      1. for details
   1. rapidly escape
      1. simple summation
      1. or broad understanding
1. to make trees
   1. that branch
      1. and branch
      1. some more
   1. multiplying
      1. over
      1. and over
