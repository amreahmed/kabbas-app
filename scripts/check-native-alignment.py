"""Check every packaged 64-bit ELF load segment for 16 KB compatibility."""
from pathlib import Path
import struct, sys, zipfile
bundle = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/app/outputs/bundle/release/app-release.aab')
checked = []
with zipfile.ZipFile(bundle) as archive:
    for name in archive.namelist():
        if not name.endswith('.so') or not any(a in name for a in ['/arm64-v8a/', '/x86_64/']):
            continue
        data = archive.read(name)
        assert data[:4] == b'\x7fELF' and data[4] == 2, name
        endian = '<' if data[5] == 1 else '>'
        phoff = struct.unpack_from(endian + 'Q', data, 32)[0]
        phsize, phnum = struct.unpack_from(endian + 'HH', data, 54)
        alignments = []
        for n in range(phnum):
            fields = struct.unpack_from(endian + 'IIQQQQQQ', data, phoff + n * phsize)
            if fields[0] == 1:
                offset, vaddr, alignment = fields[2], fields[3], fields[7]
                assert alignment >= 16384 and (vaddr - offset) % 16384 == 0, (name, fields)
                alignments.append(alignment)
        assert alignments, name
        checked.append(name)
        print('PASS', name, 'PT_LOAD alignments:', ', '.join(hex(a) for a in alignments))
assert checked, 'No 64-bit native libraries found'
print(f'{len(checked)} native libraries support 16 KB segment alignment.')
