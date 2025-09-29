[![CI](https://github.com/allyourcodebase/libssh2/actions/workflows/ci.yaml/badge.svg)](https://github.com/allyourcodebase/libssh2/actions)

# libssh2

This is [libssh2](https://github.com/libssh2/libssh2), packaged for [Zig](https://ziglang.org/).

## Installation

First, update your `build.zig.zon`:

```
# Initialize a `zig build` project if you haven't already
zig init
zig fetch --save git+https://github.com/allyourcodebase/libssh2.git#libssh2-1.11.1
```

You can then import `libssh2` in your `build.zig` with:

```zig
const libssh2_dependency = b.dependency("libssh2", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(libssh2_dependency.artifact("ssh2"));
```

## Build Options

`libssh2` offers a few options which you can control like so:

```zig
const libssh2_dependency = b.dependency("libssh2", .{
    .target = target,
    .optimize = optimize,
    .zlib = true, // links to zlib for payload compression if enabled (default=true)
    .strip = true, // Strip debug information (default=false)
    .linkage = .static, // Whether to link statically or dynamically (default=static)
    .@"crypto-backend" = .auto, // auto will to default to wincng on windows, openssl everywhere else. (default=auto)
});
```

```

```
