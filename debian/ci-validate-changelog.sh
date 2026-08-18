#!/bin/sh
set -euo pipefail
CHLOG="debian/changelog"

if [ ! -f "$CHLOG" ]; then
  echo "ERROR: $CHLOG not found"
  exit 2
fi

if command -v dpkg-parsechangelog >/dev/null 2>&1; then
  dpkg-parsechangelog -l "$CHLOG"
  echo "dpkg-parsechangelog: OK"
  exit 0
fi

# Fallback validator using Python
python3 - <<'PY'
import re,sys
p="debian/changelog"
try:
    s=open(p).read()
except Exception as e:
    print('ERROR: cannot read',p, e)
    sys.exit(2)
errors=[]
if not re.search(r'^[A-Za-z0-9+_.-]+ \([^\)]+\) [^;]+; urgency=[a-z]+\s*$', s, re.M):
    errors.append('Missing or malformed header line.')
if not re.search(r'^\s*\*\s+', s, re.M):
    errors.append('No bullet changelog entries found.')
if not re.search(r'^ -- .+ <[^>]+>  .+$', s, re.M):
    errors.append("Missing or malformed signature line (starts with ' -- ').")
if not s.endswith('\n'):
    errors.append('File does not end with a newline.')
if errors:
    print('INVALID')
    for e in errors:
        print('- ' + e)
    sys.exit(2)
print('OK')
PY
