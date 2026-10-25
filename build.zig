const std = @import("std");

const version: std.SemanticVersion = .{ .major = 1, .minor = 11, .patch = 1 };

const CryptoBackend = enum {
    openssl,
    mbedtls,
    libgcrypt,
    wincng,
};

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("libssh2", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode") orelse .static;
    const strip = b.option(bool, "strip", "Omit debug information");
    const pic = b.option(bool, "pic", "Produce Position Independent Code");

    const crypto: CryptoBackend = b.option(
        CryptoBackend,
        "crypto-backend",
        "Crypto backend: openssl|mbedtls|libgcrypt|wincng",
    ) orelse switch (target.result.os.tag) {
        .windows => .wincng,
        else => .openssl,
    };

    const zlib = b.option(bool, "zlib", "Enable SSH payload compression (links zlib)") orelse false;

    const is_windows = target.result.os.tag == .windows;

    const link_system_crypto = b.option(
        bool,
        "link-system-crypto-backend",
        "If true, library will link against system libraries",
    ) orelse (crypto != .mbedtls);

    const config_header = b.addConfigHeader(.{
        .style = .{
            .cmake = upstream.path("src/libssh2_config_cmake.h.in"),
        },
        .include_path = "libssh2_config.h",
    }, .{
        .LIBSSH2_API = switch (target.result.os.tag) {
            .windows => "__declspec(dllexport)",
            else => "",
        },
        .HAVE_SYS_UIO_H = !is_windows,
        .HAVE_SYS_SOCKET_H = !is_windows,
        .HAVE_NETINET_IN_H = !is_windows,
        .HAVE_ARPA_INET_H = !is_windows,
        .HAVE_INTTYPES_H = true,
    });

    const ssh2 = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .strip = strip,
        .pic = pic,
    });

    const ssh2_lib = b.addLibrary(.{
        .version = version,
        .name = "ssh2",
        .linkage = linkage,
        .root_module = ssh2,
    });
    b.installArtifact(ssh2_lib);
    ssh2_lib.installHeadersDirectory(upstream.path("include"), "", .{});

    ssh2.addConfigHeader(config_header);
    ssh2.addIncludePath(upstream.path("include"));
    ssh2.addCMacro("HAVE_CONFIG_H", "1");
    ssh2.addCSourceFiles(.{ .files = ssh2_src, .root = upstream.path(""), .flags = ssh2_flags });

    switch (crypto) {
        .mbedtls => {
            ssh2.addCMacro("LIBSSH2_MBEDTLS", "1");
            if (link_system_crypto) {
                ssh2.linkSystemLibrary("mbedtls", .{});
                ssh2.linkSystemLibrary("mbedcrypto", .{});
                ssh2.linkSystemLibrary("mbedx509", .{});
            } else {
                if (b.lazyDependency("mbedtls", .{
                    .target = target,
                    .optimize = optimize,
                })) |mbedtls_dep| {
                    ssh2.linkLibrary(mbedtls_dep.artifact("mbedtls"));
                }
            }
        },
        .openssl => {
            ssh2.addCMacro("LIBSSH2_OPENSSL", "1");
            if (link_system_crypto) {
                ssh2.linkSystemLibrary("ssl", .{});
                ssh2.linkSystemLibrary("crypto", .{});
            }
        },
        .wincng => {
            ssh2.addCMacro("LIBSSH2_WINCNG", "1");
            if (link_system_crypto) {
                ssh2.linkSystemLibrary("bcrypt", .{});
                ssh2.linkSystemLibrary("ncrypt", .{});
            }
        },
        .libgcrypt => {
            ssh2.addCMacro("LIBSSH2_LIBGCRYPT", "1");
            if (link_system_crypto) {
                ssh2.linkSystemLibrary("gcrypt", .{});
            }
        },
    }

    if (zlib) {
        if (b.systemIntegrationOption("zlib", .{})) {
            ssh2.linkSystemLibrary("zlib", .{});
        } else if (b.lazyDependency("zlib", .{
            .target = target,
            .optimize = optimize,
        })) |zlib_dependency| {
            ssh2.linkLibrary(zlib_dependency.artifact("z"));
        }
    }
}

pub const ssh2_src: []const []const u8 = &.{
    "src/agent.c",
    "src/bcrypt_pbkdf.c",
    "src/blowfish.c",
    "src/chacha.c",
    "src/channel.c",
    "src/cipher-chachapoly.c",
    "src/comp.c",
    "src/crypt.c",
    "src/global.c",
    "src/hostkey.c",
    "src/keepalive.c",
    "src/kex.c",
    "src/knownhost.c",
    "src/mac.c",
    "src/misc.c",
    "src/packet.c",
    "src/pem.c",
    "src/poly1305.c",
    "src/publickey.c",
    "src/scp.c",
    "src/session.c",
    "src/sftp.c",
    "src/transport.c",
    "src/userauth.c",
    "src/userauth_kbd_packet.c",
    "src/version.c",
    "src/crypto.c",
};

pub const ssh2_flags: []const []const u8 = &.{};
