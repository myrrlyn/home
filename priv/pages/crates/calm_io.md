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
