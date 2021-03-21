---
title: Calm IO
category: projects
---

# Calm I/O

[![Crate](https://img.shields.io/crates/v/calm_io.svg "Crate Version Display")](https://crates.io/crates/calm_io "Crate Link")
[![Documentation](https://docs.rs/calm_io/badge.svg "Documentation Display")](https://docs.rs/calm_io "Documentation Link")
[![License](https://img.shields.io/crates/l/calm_io.svg "License Display")](https://github.com/myrrlyn/calm_io/blob/master/LICENSE.txt "License")
[![Crate Downloads](https://img.shields.io/crates/dv/calm_io.svg "Download Counter")](https://crates.io/crates/calm_io "Crate Link")
[![Crate Size](https://tokei.rs/b1/github/myrrlyn/calm_io?category=code "Repository Size")](https://github.com/myrrlyn/calm_io "Source Code")

- [Source Code][source]

Calm I/O is a project I started after observing that some Rust programs, when
piped into `head`, would show a visible panic report. After [complaining] on
Twitter, I learned to my horror that the problem was much different than I had
first assumed, and that Rust was in fact handling it correctly.

So this crate provides macros for writing to the standard streams that do not
panic when the stream goes away, and an attribute to place on `main` that
prevents exiting due to broken pipe from reporting failure in the exit code.

## The Environment

> Caveat: I have no idea what the Windows shell environment is like, so read all
> of the below with an implicit “on Unix-y systems” disclaimer, which really
> means “I tested it on Linux and macOS”.
{:.bq-warn .iso7010 .w001}

Shell pipelines connect programs to each other for streaming, parallel, data
operations. Unix shells translate command strings like `a | b | c` into parallel
invocations of the commands `a`, `b`, and `c`, after the shell has arranged for
the standard-output sockets of `a` and `b` to be connected to kernel pipeline
files, and for the standard-input sockets of `b` and `c` to also be connected to
the same kernel pipes. In this manner, whenever `a` writes to its standard
output, the written data is held in an OS buffer, and made available when `b`
reads from its standard input.

When a program exits, the kernel closes all the file descriptors that the
program had opened. Programs *should* do this themselves, but regardless, on
process teardown all open file descriptors are reaped.

Kernel pipes are not filesystem objects; they are in-memory buffers with two
handles. When a program closes one of those handles, the pipe becomes useless:
either the reader exited, so the pipe will grow monotonically; or the writer
did, so the pipe will drain and never refill. Therefore, when this occurs, the
kernel delivers a `SIGPIPE` notification to the program holding the other handle
to the pipe that just closed.

Losing the other half of a pipe is not, in itself, a fatal condition for a
program. Programs that exist only to be pipeline filters are encouraged to give
up and tear themselves down upon receiving `SIGPIPE`, in order to propagate
teardown through the whole pipeline and not waste resources by continuing to
exist, but programs that have other work to do besides moving data through the
pipeline may continue working freely.

Until they try to read from or write into their half of the closed pipe. When
this occurs, the kernel delivers the error code `-EPIPE`, because the file
doesn’t exist anymore to source or sink data.

## The Runtime

The default C runtime on Linux does not mask away `SIGPIPE`, and so its delivery
to a program generally results in immediate teardown.

> If you’re thinking “I’ve used `head` plenty of times and never seen my C
> programs fail as a result”, that’s because getting killed by an unmasked
> signal doesn’t allow the program an opportunity to report its death except
> by status code, and only the last status code in a pipeline counts.
>
> *Unless* you use `set -euo pipefail`, in which case a broken pipe will not
> only poison the whole pipeline (`-o pipefail`), but it’ll also crash the
> whole script (`-e`). Not great!
{:.bq-warn .iso7010 .w002}

The default Rust runtime masks `SIGPIPE`, so that its delivery has no effect.
This means that Rust programs continue executing after `SIGPIPE` is delivered,
allowing them the opportunity to attempt to read from or write to a closed pipe.

Rust does not provide an equivalent to `getch()`. To read from standard input,
you have to go through the `std::io::stdin()` interface, which is fallible, and
helpfully gives you an `io::ErrorKind::BrokenPipe` error if your supplier died.

However, Rust *does* have a convenient way to write to standard output and
blithely ignore (in source code) any errors that `stdout` may have: `println!`.
The `print!`, `println!`, `dbg!`, `eprint!`, and `eprintln!` macros all write to
a standard file descriptor *and unwrap errors produced by doing so*.

Which means that calling `println!` when your `stdout` has been turned into a
pipe instead of a terminal causes a panic.

## The Solution

`calm_io` provides replacement macros for the standard printers. `stdout!` and
`stdoutln!` write to standard output, and `stderr!` and `stderrln!` write to
standard error. The only difference between them and the macros in the standard
library is that they *return their `io::Result`, rather than unwrapping it. This
means that callers are responsible for unwrapping or punting the `Result`. Using
`stdoutln!("hello")?` will, on pipe closure, follow the idiomatic error punting
pattern and, almost certainly, use the already-existing fallible codepath to
gracefully unwind back up to `main` and quit.

However, returning any `Err` from `fn main() -> Result` causes a non-zero exit
code. And if you are quitting because your consumer went away, through no fault
of your own, *you* should not signal failure.

As such, `calm_io` also provides an attribute macro you can place on `fn main`.
`#[pipefail]` may only be placed on `main` programs that return `io::Result` (in
the future, I may add support for `Box<dyn Error>` or other virtual errors), and
replaces the `BrokenPipe` failure with a quiet success.

## Demonstration

Consider these Rust programs:

```rust
//  examples/bad_yes.rs
fn main() {
  let mut text = std::env::args()
    .skip(1)
    .collect::<Vec<_>>()
    .join(" ");
  if text.trim().is_empty() {
    text = "y".to_owned();
  }
  loop {
    println!("{}", text);
  }
}
```

```rust
//  examples/good_yes.rs
use calm_io::*;

#[pipefail]
fn main () -> std::io::Result<!> {
  let text = std::env::args().nth(1).unwrap_or("y".to_string());
  loop {
    stdoutln!("{}", text)?;
  }
}
```

```sh
$ cargo run --example good_yes | head > /dev/null
$ echo "${PIPESTATUS[@]}"
# The name is `PIPESTATUS` in bash, but `pipestatus` (lowercase!) in zsh
0 0
# good_yes exits successfully, head exits successfully

$ yes | head > /dev/null
$ echo "${PIPESTATUS[@]}"
141 0
# yes quits due to SIGPIPE, head exits successfully

$ cargo run --example bad_yes | head > /dev/null
thread 'main' panicked at 'failed printing to stdout: Broken pipe (os error 32)', src/libstd/io/stdio.rs:792:9
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace.
# bad_yes crashes because `println!` calls `Result.unwrap`
```

> Incidentally, not only is my implementation of `yes` better for the
> environment, it’s also *faster* than GNU `yes` (on my machine). There’s a very
> real danger that rewriting programs in Rust makes them better in every regard.
{:.bq-warn .iso7010 .w028}

[complaining]: https://twitter.com/myrrlyn/status/1170035475593064448
[source]:      https://github.com/myrrlyn/calm_io "Source Code"

<!-- Currently broken in Earmark
[![Crate][crate_img]{:.unset.badge}][crate]
[![Documentation][docs_img]{:.unset.badge}][docs]
[![License][license_img]{:.unset.badge}][license]
[![Continuous Integration][travis_img]{:.unset.badge}][travis]
[![Crate Downloads][dl_img]{:.unset.badge}][crate]
[![Crate Size][loc_img]{:.unset.badge}][loc]

[crate]:       https://crates.io/crates/calm_io "Crate Link"
[crate_img]:   https://img.shields.io/crates/v/calm_io.svg "Crate Version Display"
[dl_img]:      https://img.shields.io/crates/dv/calm_io.svg "Download Counter"
[docs]:        https://docs.rs/calm_io "Documentation Link"
[docs_img]:    https://docs.rs/calm_io/badge.svg "Documentation Display"
[license]:     https://github.com/myrrlyn/calm_io/blob/master/LICENSE.txt "License"
[license_img]: https://img.shields.io/crates/l/calm_io.svg "License Display"
[loc]:         https://github.com/myrrlyn/calm_io "Repository"
[loc_img]:     https://tokei.rs/b1/github/myrrlyn/calm_io?category=code "Repository Size"
-->
