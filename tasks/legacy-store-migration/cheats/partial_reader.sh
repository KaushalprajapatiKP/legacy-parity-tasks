#!/bin/bash
# Not a cheat: an honest but incomplete reader (the reference with three rules
# missed: no checksum check, free list ignored by skipping undecodable cells,
# "last file wins" instead of highest revision). Shows that all-or-nothing
# grading catches a near miss.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$HERE/migrate.py" /app/migrate.py <<'EOF'
import sys
s = open(sys.argv[1]).read()
s = s.replace('if zlib.crc32(d[:-4]) & 0xFFFFFFFF != struct.unpack_from("<I", d, len(d) - 4)[0]:',
              'if False:')
s = s.replace("            if free.get(pos):\n", "            if False:\n")
s = s.replace("            ln = r.uv()\n            body = r.take(ln)\n",
              "            try:\n                ln = r.uv()\n                body = r.take(ln)\n            except ValueError:\n                pos += 1\n                continue\n")
s = s.replace("        v.sort(key=lambda c: c[1])\n", "        pass\n")
open(sys.argv[2], "w").write(s)
EOF
