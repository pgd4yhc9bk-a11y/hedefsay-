#!/usr/bin/env bash
# Çekirdeğin tek kaynağı prototip/ — Edge Function'lar aynı kodu kullansın diye _shared'a kopyalanır.
# (supabase functions deploy yalnızca functions/ altını paketler.) prototip/test.js kopyaların güncel olduğunu denetler.
set -euo pipefail
KOK="$(cd "$(dirname "$0")/.." && pwd)"
cp "$KOK/prototip/oyun.js" "$KOK/prototip/sozluk.js" "$KOK/supabase/functions/_shared/"
echo "_shared güncellendi"
