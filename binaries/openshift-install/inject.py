#!/usr/bin/env python3
"""Inject release values into an openshift-install binary like `oc adm release extract`.

Reproduces openshift/oc pkg/cli/admin/release/extract_tools.go (release-4.22):
copyAndReplace() overwrites the first occurrence of each marker with the value
plus one NUL byte and leaves the rest of the marker untouched, and
codesign.ResignMacho() re-creates the Go-linker ad-hoc signature of darwin/arm64
binaries afterwards. The input is only read and written as bytes, so binaries
of any architecture can be processed on any host.
"""
import argparse
import hashlib
import mmap
import struct
import sys

MARKERS = {
    "image": b"\x00_RELEASE_IMAGE_LOCATION_\x00" + b"X" * 300 + b"\x00",
    "version": b"\x00_RELEASE_VERSION_LOCATION_\x00" + b"X" * 64 + b"\x00",
    "arch": b"\x00_RELEASE_ARCHITECTURE_LOCATION_\x00" + b"X" * 64 + b"\x00",
}

MH_MAGIC_64 = 0xFEEDFACF
MH_EXECUTE = 0x2
LC_SEGMENT_64 = 0x19
LC_CODE_SIGNATURE = 0x1D
PAGE_SIZE_BITS = 12
PAGE_SIZE = 1 << PAGE_SIZE_BITS
CODE_DIRECTORY_SIZE = 13 * 4 + 4 + 4 * 8
SUPER_BLOB_SIZE = 3 * 4
BLOB_SIZE = 2 * 4
SIGN_ID = b"a.out"


def inject(mm, values):
    """Overwrite the first occurrence of each marker; return the names not found."""
    missing = []
    for name, value in values.items():
        marker = MARKERS[name]
        data = value.encode()
        if len(data) > len(marker) - 1:
            raise SystemExit(
                f"the {name} value has {len(data)} bytes, but the maximum replacement length is {len(marker) - 1}"
            )
        index = mm.find(marker)
        if index == -1:
            missing.append(name)
            continue
        mm[index : index + len(data)] = data
        mm[index + len(data)] = 0
    return missing


def signature_size(code_size):
    nhashes = (code_size + PAGE_SIZE - 1) // PAGE_SIZE
    hash_off = CODE_DIRECTORY_SIZE + len(SIGN_ID) + 1
    return SUPER_BLOB_SIZE + BLOB_SIZE + hash_off + nhashes * 32


def resign_macho(mm):
    """Re-create the ad-hoc signature exactly like oc codesign.signSingleFile; return True if signed."""
    if len(mm) < 32 or struct.unpack_from("<I", mm, 0)[0] != MH_MAGIC_64:
        return False
    filetype, ncmds = struct.unpack_from("<II", mm, 12)
    text_off = text_size = None
    sig = None
    off = 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", mm, off)
        if cmd == LC_SEGMENT_64 and mm[off + 8 : off + 24].rstrip(b"\x00") == b"__TEXT":
            text_off, text_size = struct.unpack_from("<QQ", mm, off + 40)
        elif cmd == LC_CODE_SIGNATURE:
            sig = struct.unpack_from("<II", mm, off + 8)
        off += cmdsize
    if sig is None or text_off is None:
        return False
    code_size, data_size = sig
    if signature_size(code_size) != data_size:
        return False
    nhashes = (code_size + PAGE_SIZE - 1) // PAGE_SIZE
    hash_off = CODE_DIRECTORY_SIZE + len(SIGN_ID) + 1
    out = bytearray()
    out += struct.pack(">III", 0xFADE0CC0, data_size, 1)
    out += struct.pack(">II", 0, SUPER_BLOB_SIZE + BLOB_SIZE)
    out += struct.pack(
        ">IIIIIIIIIBBBBIIIIQQQQ",
        0xFADE0C02,
        data_size - (SUPER_BLOB_SIZE + BLOB_SIZE),
        0x20400,
        0x20002,
        hash_off,
        CODE_DIRECTORY_SIZE,
        0,
        nhashes,
        code_size,
        32,
        2,
        0,
        PAGE_SIZE_BITS,
        0,
        0,
        0,
        0,
        0,
        text_off,
        text_size,
        1 if filetype == MH_EXECUTE else 0,
    )
    out += SIGN_ID + b"\x00"
    for p in range(0, code_size, PAGE_SIZE):
        out += hashlib.sha256(mm[p : min(p + PAGE_SIZE, code_size)]).digest()
    mm[code_size : code_size + data_size] = bytes(out)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("binary", help="file to modify in place")
    parser.add_argument("--image", required=True, help="release image pullspec, e.g. quay.io/...@sha256:...")
    parser.add_argument("--version", required=True, help="release name, e.g. 4.22.18")
    parser.add_argument("--arch", required=True, help="release platform, e.g. linux/amd64 or 'multi (linux/amd64)'")
    parser.add_argument("--resign-macho", action="store_true", help="re-sign darwin/arm64 binaries like oc does")
    parser.add_argument(
        "--require",
        default="image,version,arch",
        help="comma-separated markers that must exist; oc only warns, but a missing marker here fails the build",
    )
    args = parser.parse_args()
    required = {name for name in args.require.split(",") if name}
    unknown = required - set(MARKERS)
    if unknown:
        sys.exit(f"unknown markers in --require: {', '.join(sorted(unknown))}")
    with open(args.binary, "r+b") as f, mmap.mmap(f.fileno(), 0) as mm:
        missing = inject(mm, {"image": args.image, "version": args.version, "arch": args.arch})
        missing_required = sorted(required.intersection(missing))
        if missing_required:
            sys.exit(f"{args.binary}: markers not found: {', '.join(missing_required)}")
        signed = resign_macho(mm) if args.resign_macho else False
        mm.flush()
    injected = [name for name in MARKERS if name not in missing]
    print(f"{args.binary}: injected {', '.join(injected)}{'; re-signed' if signed else ''}")


if __name__ == "__main__":
    main()
