#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$ROOT/env.sh" ] && source "$ROOT/env.sh"
cd "$ROOT/servo"
./mach package --ohos --release --flavor=harmonyos
find target/openharmony -name "*.hap" -maxdepth 8 2>/dev/null || true
