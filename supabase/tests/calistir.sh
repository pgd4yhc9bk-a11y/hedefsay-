#!/usr/bin/env bash
# Geçici bir PostgreSQL kümesi açıp migration'ları ve şema testlerini çalıştırır.
# Kullanım: supabase/tests/calistir.sh   (PG_BIN ile bin dizini verilebilir; root ise 'postgres' kullanıcısıyla çalışır)
set -euo pipefail
PG_BIN="${PG_BIN:-$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | tail -1)}"
AYIR="$(cd "$(dirname "$0")" && pwd)"
KOK="$(dirname "$(dirname "$AYIR")")"
DIZIN="$(mktemp -d "${TMPDIR:-/tmp}/hedef-pg.XXXXXX")"
PORT="${PGPORT_TEST:-54329}"
if [ "$(id -u)" = 0 ]; then
  chown postgres "$DIZIN"; chmod 755 "$DIZIN"
  chmod -R a+rX "$KOK/supabase" 2>/dev/null || true
  CALISTIR=(su postgres -s /bin/bash -c)
else
  CALISTIR=(bash -c)
fi
run() { "${CALISTIR[@]}" "$1"; }
cleanup() { run "$PG_BIN/pg_ctl -D $DIZIN/veri stop -m immediate >/dev/null 2>&1" || true; rm -rf "$DIZIN"; }
trap cleanup EXIT
run "$PG_BIN/initdb -D $DIZIN/veri -A trust >/dev/null"
run "$PG_BIN/pg_ctl -D $DIZIN/veri -o '-p $PORT -k $DIZIN -c listen_addresses=' -l $DIZIN/log -w start >/dev/null"
PSQL="psql -h $DIZIN -p $PORT -U postgres -q -v ON_ERROR_STOP=1 -d postgres"
run "$PSQL -f $AYIR/stub.sql"
for m in "$KOK"/supabase/migrations/*.sql; do run "$PSQL -f $m"; done
run "$PSQL -f $AYIR/sema_test.sql"
