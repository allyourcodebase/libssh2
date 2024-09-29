const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libssh2_dep = b.dependency("libssh2", .{
        .target = target,
        .optimize = optimize,
    });

    const mbedtls_dep = b.dependency("mbedtls", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "ssh2",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.addIncludePath(libssh2_dep.path("include"));
    lib.linkLibrary(mbedtls_dep.artifact("mbedtls"));
    lib.addCSourceFiles(.{
        .root = libssh2_dep.path("src"),
        .flags = &.{},
        .files = &.{
            "channel.c",
            "comp.c",
            "crypt.c",
            "hostkey.c",
            "kex.c",
            "mac.c",
            "misc.c",
            "packet.c",
            "publickey.c",
            "scp.c",
            "session.c",
            "sftp.c",
            "userauth.c",
            "transport.c",
            "version.c",
            "knownhost.c",
            "agent.c",
            "mbedtls.c",
            "pem.c",
            "keepalive.c",
            "global.c",
            "blowfish.c",
            "bcrypt_pbkdf.c",
            "agent_win.c",
        },
    });
    lib.installHeader(b.path("config/libssh2_config.h"), "libssh2_config.h");
    lib.installHeadersDirectory(libssh2_dep.path("include"), ".", .{});
    lib.defineCMacro("LIBSSH2_MBEDTLS", null);

    if (target.result.os.tag == .windows) {
        lib.defineCMacro("_CRT_SECURE_NO_DEPRECATE", "1");
        lib.defineCMacro("HAVE_LIBCRYPT32", null);
        lib.defineCMacro("HAVE_WINSOCK2_H", null);
        lib.defineCMacro("HAVE_IOCTLSOCKET", null);
        lib.defineCMacro("HAVE_SELECT", null);
        lib.defineCMacro("LIBSSH2_DH_GEX_NEW", "1");

        if (target.result.isGnu()) {
            lib.defineCMacro("HAVE_UNISTD_H", null);
            lib.defineCMacro("HAVE_INTTYPES_H", null);
            lib.defineCMacro("HAVE_SYS_TIME_H", null);
            lib.defineCMacro("HAVE_GETTIMEOFDAY", null);
        }
    } else {
        lib.defineCMacro("HAVE_UNISTD_H", null);
        lib.defineCMacro("HAVE_INTTYPES_H", null);
        lib.defineCMacro("HAVE_STDLIB_H", null);
        lib.defineCMacro("HAVE_SYS_SELECT_H", null);
        lib.defineCMacro("HAVE_SYS_UIO_H", null);
        lib.defineCMacro("HAVE_SYS_SOCKET_H", null);
        lib.defineCMacro("HAVE_SYS_IOCTL_H", null);
        lib.defineCMacro("HAVE_SYS_TIME_H", null);
        lib.defineCMacro("HAVE_SYS_UN_H", null);
        lib.defineCMacro("HAVE_LONGLONG", null);
        lib.defineCMacro("HAVE_GETTIMEOFDAY", null);
        lib.defineCMacro("HAVE_INET_ADDR", null);
        lib.defineCMacro("HAVE_POLL", null);
        lib.defineCMacro("HAVE_SELECT", null);
        lib.defineCMacro("HAVE_SOCKET", null);
        lib.defineCMacro("HAVE_STRTOLL", null);
        lib.defineCMacro("HAVE_SNPRINTF", null);
        lib.defineCMacro("HAVE_O_NONBLOCK", null);
    }

    b.installArtifact(lib);
}
