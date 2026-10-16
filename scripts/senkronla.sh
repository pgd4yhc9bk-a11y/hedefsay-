#!/usr/bin/env bash
# Çekirdeğin tek kaynağı prototip/ — Edge Function'lar ve Expo istemcisi aynı kodu kullansın diye kopyalanır.
# (supabase functions deploy yalnızca functions/ altını, Metro yalnızca istemci/ altını paketler.)
# prototip/test.js kopyaların güncel olduğunu denetler.
set -euo pipefail
KOK="$(cd "$(dirname "$0")/.." && pwd)"
for hedef in supabase/functions/_shared istemci/src/cekirdek; do
  cp "$KOK/prototip/oyun.js" "$KOK/prototip/sozluk.js" "$KOK/$hedef/"
done
echo "kopyalar güncellendi"
