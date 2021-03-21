---
title: Résumé – Alexander Payne
category: personal
---

# My Résumé

I am a software engineer with experience in low-level firmware and application
development. I am trained in technical writing and system design, with
emphasises on user comprehension and fault tolerance.

## Professional Experience

I have been employed as a software engineer since 2016 Dec. The nature of my
work as a federal subcontractor limits the detail I can write here.

### Amazon Web Services

Dates: 2020 Jul 6 – present

Role: Software Development Engineer

Responsibility: I am the Rust subject matter expert on my team. We are
researching Rust’s applicability for use in novel devices operating under tight
performance constraints and subject to strict safety and correctness
regulations.

### Space Dynamics Laboratory

Dates: 2016 Dec 5 - 2020 May 28

Departure: personal, voluntary, amicable

Responsibility: I was a Satellite Software Engineer working on the development
and testing of flight control systems of CubeSat research vehicles. I worked
primarily in C++, with some C for more esoteric devices and Ruby for ground
control software.

Certifications: TS/SCI

#### Projects

In order of decreasing recency:

- VPM; USAF/Kirtland AFB

  I wrote flight software systems in C++ using SDL’s framework for distributed
  service control. VPM was successfully launched and operated from Kirtland and
  SDL facilities.

- EAGLE; USAF/Kirtland AFB

  I wrote ground control software that generated tasking routines for
  transmission to the vehicle.

- DHFR; DARPA/MIT

  I wrote ground control software interfaces and automation, and performed
  operations for four months. My satellite was eventually found to have been
  destroyed by the launch.

- BioSentinel; NASA Ames

  I wrote a kernel driver for VxWorks that bridged the primary computer and a
  secondary FPGA holding multiple peripherals.

### Research

As part of my work with the [COSMOS][cosmos] framework, I wrote Rust programs to
act as data pipeline filters and C++/Ruby code generators. This research
indirectly led to the creation of [`bitvec`][bv].

## Personal Experience

I develop software for a hobby as well as for a career.

### Rust Crates

I am the author or maintainer of a number of Rust libraries. You can read more
about them at my [crate listing][crates]. I have been an active Rust author
since 2016, and am considered an expert by my employer and the general Rust
community.

### Web Design

This website is self-authored, atop the Phoenix framework.

## Education

Trine University: 2011 – 2016. Studied Computer Engineering, B.Sc.

Notable courses:

- ***Senior Design***: My capstone project was the construction and programming
  of an autonomous cargo hauler. I worked with three mechanical engineers on the
  physical machine, and personally built the electrical and software systems.
  The machine capably navigated along a pre-programmed route, and successfully
  detected obstacles such as pedestrians and a train. The code is on my GitHub
  profile, and the summary video is [on YouTube][srd]. I can provide design
  documents upon request.

- **Logic and Computer Design**: This class focused on the hardware construction
  of a computer and the instruction primitives executing on it. We built a
  five-stage MIPS CPU in Verilog.

- **Embedded Systems**: This class taught real-time operating systems and
  freestanding programming. We built an oscilloscope and basic RTOS.

[bv]: /crates/bv
[cosmos]: https://cosmosrb.com
[crates]: /crates
[srd]: https://www.youtube.com/watch?v=K3CKSovJbJQ
