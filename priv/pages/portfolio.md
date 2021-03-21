---
title: Portfolio – Alexander Payne
category: personal
---

# My Portfolio

Here are some faded aspects of my hobby. Other than my F/LOSS work, these
largely have not been touched since 2016.

## Cosmonaut

Cosmonaut is a long-term, extremely incomplete, personal project on which I’m
working, inspired by things I encounter at my day job. It began as an
educational project for me to learn how to write a parser, and now aims to
provide a complement to the [COSMOS](//cosmosrb.com) project by Ball Aerospace.

Currently, it can parse COSMOS definition files and create a dictionary in Rust
whose members can be used to serialize a record into the bitstream that the
COSMOS text defines. I wrote the `bitvec` crate specifically to address the fact
that COSMOS definitions of wire protocols permit, and we use at work, fields
that are a combination of:

- not an even multiple of bytes in width
- not guaranteed to start or end on a byte boundary
- able to cross a byte boundary

These constraints are impossible to cleanly service in standard Rust, and the
other bit-vector libraries I encountered did not support such manipulation.
*Furthermore*, because I work in esoteric hardware, the endianness of *bits in*
*an element* matters to the network layer, so I need to bring both `bitvec` and
`endian_trait` into play in order to match the bitstream that actually transfers
over the wire.

## Rust Crates

These are described in detail in [their own section][crates]

## This Website

My talents and education lie primarily in architecture and engineering. I firmly
believe in the importance of a broad skill set and mastery of new topics. I
designed this website myself to understand design and UI concepts. I also
improved my understanding of systems administration and networking by hosting it
myself.

The code governing this site is [available on GitHub][site].

## Senior Design

My Senior Design project is the largest and most complex project I have
completed to date. The code itself is available on [my GitHub profile][srd]. Our
team also created a [YouTube video][yt] summary of the completed vehicle. I can
provide other documents such as our design specifications, presentations, and
reports upon request.

I designed a robust Real-Time Operating System capable of using both scheduled
and interrupt-driven tasks to drive an autonomous vehicle. I also wrote the
hardware drivers for my peripherals – GPS, compass, ultrasonic sensors, and
motors – and the RTOS modules which consumed them.

My software design received high marks from my professors, and the system
interfaced flawlessly with the hardware. Our public demonstration was a complete
success, and we were able to navigate our route fully without colliding with
pedestrians or straying off of the sidewalk.

The software I engineered demonstrates my excellent grasp of the software design
patterns and engineering principles requisite in any complex project.

## MIPS CPU

For my Logic and Computer Design class, I implemented a 32-bit pipelined MIPS
CPU in Verilog. I am not able to showcase the code from that class due to some
licensing constraints. My design included features such as:

- Five-stage pipeline with operand forwarding and stall detection
- 32-element register file with half-cycle latency
- ALU with replaceable arithmetic logic
  - Ripple-carry addition at first
  - Look-ahead-carry addition
  - Finally, Kogge-Stone addition
- RAM access (we also designed the RAM banks and controllers)
- von Neumann architecture: I was able to load and execute basic MIPS object
    code with my project, and support self-modifying program execution.
- Access to peripheral devices using drivers I wrote

## Hermaeus

Hermaeus ([homepage][hm-myrr], [source code][hm-gh], [Gem page][hm-gem]) is a
scripted reddit client designed to archive posts. It operates by processing
index pages and retrieving the content they reference. Hermaeus is capable of
reformatting the downloaded text and storing it to disk; future goals include
storing texts in SQL and NoSQL databases, and powering a website for public
browsing of the archive it manages.

One of my design goals with Hermaeus is to have it be usable by non-technical
people, namely, the moderators of a reddit community I frequent and for whom it
was designed. Hermaeus achieves this goal with an easy-to-use launcher script.

## Computer Assembly and System Administration

I built my server and desktop. Both are currently out of service, as they are
eight and six years old and badly worn. When they lived, they ran Windows and
Arch Linux.

## /r/teslore CSS

I architected the stylesheet for [/r/teslore][tsl]. The source code for the
current sheet is [here][tsl-gh-old]; it is several years old and showing it. I
am rebuilding the sheet in my spare time, but unfortunately am not at liberty to
publicize any part of the code yet.

[crates]: /crates
[hm-gem]: https://rubygems.org/gems/hermaeus
[hm-gh]: https://github.com/myrrlyn/hermaeus
[hm-myrr]: https://myrrlyn.net/hermaeus
[sass]: http://sass-lang.com
[site]: https://github.com/myrrlyn/myrrlyn.net
[srd]: https://github.com/myrrlyn/SeniorDesign
[tsl]: https://reddit.com/r/teslore
[tsl-gh-old]: https://github.com/myrrlyn/teslore
[yt]: https://www.youtube.com/watch?v=K3CKSovJbJQ
