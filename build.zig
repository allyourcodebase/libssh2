const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version: std.SemanticVersion = .{ .major = 1, .minor = 11, .patch = 1 };

    const libssh2_dep = b.dependency("libssh2", .{
        .target = target,
        .optimize = optimize,
    });

    const mbedtls_dep = b.dependency("mbedtls", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib = b.addLibrary(.{
        .name = "ssh2",
        .version = version,
        .root_module = lib_mod,
        .linkage = .static,
    });
    lib_mod.addIncludePath(libssh2_dep.path("include"));
    lib_mod.linkLibrary(mbedtls_dep.artifact("mbedtls"));
    lib_mod.addCSourceFiles(.{
        .root = libssh2_dep.path("src"),
        .flags = &.{},
        .files = &.{
            "agent.c",
            "bcrypt_pbkdf.c",
            "blowfish.c",
            "chacha.c",
            "channel.c",
            "cipher-chachapoly.c",
            "comp.c",
            "crypt.c",
            "global.c",
            "hostkey.c",
            "keepalive.c",
            "kex.c",
            "knownhost.c",
            "libgcrypt.c",
            "mac.c",
            "mbedtls.c",
            "misc.c",
            "openssl.c",
            "os400qc3.c",
            "packet.c",
            "pem.c",
            "poly1305.c",
            "publickey.c",
            "scp.c",
            "session.c",
            "sftp.c",
            "transport.c",
            "userauth.c",
            "userauth_kbd_packet.c",
            "version.c",
            "wincng.c",
        },
    });
    lib.installHeader(b.path("config/libssh2_config.h"), "libssh2_config.h");
    lib.installHeadersDirectory(libssh2_dep.path("include"), ".", .{});
    lib_mod.addCMacro("LIBSSH2_MBEDTLS", "");

    if (target.result.os.tag == .windows) {
        lib_mod.addCMacro("_CRT_SECURE_NO_DEPRECATE", "1");
        lib_mod.addCMacro("HAVE_LIBCRYPT32", "");
        lib_mod.addCMacro("HAVE_WINSOCK2_H", "");
        lib_mod.addCMacro("HAVE_IOCTLSOCKET", "");
        lib_mod.addCMacro("HAVE_SELECT", "");
        lib_mod.addCMacro("LIBSSH2_DH_GEX_NEW", "1");

        if (target.result.abi.isGnu()) {
            lib_mod.addCMacro("HAVE_UNISTD_H", "");
            lib_mod.addCMacro("HAVE_INTTYPES_H", "");
            lib_mod.addCMacro("HAVE_SYS_TIME_H", "");
            lib_mod.addCMacro("HAVE_GETTIMEOFDAY", "");
        }
    } else {
        lib_mod.addCMacro("HAVE_UNISTD_H", "");
        lib_mod.addCMacro("HAVE_INTTYPES_H", "");
        lib_mod.addCMacro("HAVE_STDLIB_H", "");
        lib_mod.addCMacro("HAVE_SYS_SELECT_H", "");
        lib_mod.addCMacro("HAVE_SYS_UIO_H", "");
        lib_mod.addCMacro("HAVE_SYS_SOCKET_H", "");
        lib_mod.addCMacro("HAVE_SYS_IOCTL_H", "");
        lib_mod.addCMacro("HAVE_SYS_TIME_H", "");
        lib_mod.addCMacro("HAVE_SYS_UN_H", "");
        lib_mod.addCMacro("HAVE_LONGLONG", "");
        lib_mod.addCMacro("HAVE_GETTIMEOFDAY", "");
        lib_mod.addCMacro("HAVE_INET_ADDR", "");
        lib_mod.addCMacro("HAVE_POLL", "");
        lib_mod.addCMacro("HAVE_SELECT", "");
        lib_mod.addCMacro("HAVE_SOCKET", "");
        lib_mod.addCMacro("HAVE_STRTOLL", "");
        lib_mod.addCMacro("HAVE_SNPRINTF", "");
        lib_mod.addCMacro("HAVE_O_NONBLOCK", "");
    }

    b.installArtifact(lib);

    const lib_unit_tests_mod = b.createModule(.{
        .root_source_file = b.path("test/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests_mod.addImport("libssh2", lib_mod);
    lib_unit_tests_mod.linkLibrary(lib);
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_unit_tests_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
