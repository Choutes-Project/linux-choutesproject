# linux-choutesproject

The kernels of [Choutes Project](https://choutes.com), built from
[linux-tkg](https://github.com/Frogging-Family/linux-tkg) by Frogging-Family.

| Package | Series | Built for | Processors |
|---|---|---|---|
| `linux-choutesproject` | newest stable (7.3) | `x86-64-v3` | Intel Haswell and newer, AMD Ryzen and newer (AVX2, BMI2, FMA) |
| `linux-choutesproject-lts` | long-term (6.18) | `x86-64` (v1) | every 64-bit x86 processor, including older ones without AVX2 |

Choutes Project picks the kernel that matches the processor. `linux-lts` from Arch Linux stays
installed as a fallback in the boot menu.

## What is in it ("Choutes Project Sauce")

Every setting is in [`builds/`](builds) and [`fragments/`](fragments); nothing else is changed.

- **Scheduler:** EEVDF, the scheduler of the Linux kernel itself.
- **Timer and preemption:** 1000 Hz and full preemption.
- **Compiler:** Clang with ThinLTO; `-O3` for `linux-choutesproject`, `-O2` for the long-term series (Clang `-O3` breaks the link of 6.18), for a fixed processor level. A build never targets the processor of the machine that builds it (no `native`).
- **Gaming:** NTsync (module `ntsync`) and Fsync for Wine and Proton.
- **Scheduling and memory:** sched-ext, to change the scheduler at runtime with the scx tools; multi-generational LRU.
- **Network:** BBR as the default TCP congestion control. This is BBR as it is in the Linux kernel, not BBRv3.
- **linux-tkg patch sets:** the linux-tkg patch sets that are on by default (`glitched_base`, `zenify`, Clear Linux, misc additions).

Settings are left as the kernel has them where a change would only suit one machine:
- the default CPU frequency governor (schedutil);
- no built-in kernel command line;
- `NR_CPUS` as the kernel configuration has it;
- tracing and NUMA stay on.

## Build

The packages are built by GitHub Actions ([`.github/workflows/build.yml`](.github/workflows/build.yml)). They are built in an Arch Linux container that uses the same fixed date of the Arch repositories as Choutes Project ([`SNAPSHOT`](SNAPSHOT)). The linux-tkg version is pinned in [`TKG_COMMIT`](TKG_COMMIT).

```
scripts/build.sh v3        # or lts-v1
```

[`scripts/verify-config.sh`](scripts/verify-config.sh) fails the build when one of these is missing: EEVDF, 1000 Hz, full preemption, Clang ThinLTO, sched-ext, NTsync, MGLRU or BBR. It also fails when the processor target is not exactly the one of the build.

The packages in the releases of this repository are **unsigned build results**. Choutes Project signs them with its package key and publishes them in the `choutes` repository; install the kernels from there, not from these files.

## Status

These kernels are new. Speed is not claimed until it has been measured with benchmarks that can be repeated.

## License

GPL-2.0, like linux-tkg and the Linux kernel. See [LICENSE](LICENSE).
