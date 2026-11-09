#!/usr/bin/env bash
#
# Mengirim payload notifikasi ke iOS Simulator dan (opsional) mengambil
# screenshot sebagai bukti pengujian tiga app state.
#
# Kenapa lewat `simctl push`: iOS Simulator tidak pernah menerima APNs token,
# sehingga Firebase tidak bisa memberi FCM token di sana. `simctl push`
# menyuntikkan payload APNs langsung ke aplikasi, dan AppDelegate.swift
# meneruskannya ke Dart.
#
# Pemakaian:
#   ./tool/sim_push.sh foreground
#   ./tool/sim_push.sh background
#   ./tool/sim_push.sh terminated
#   ./tool/sim_push.sh data-only
#   ./tool/sim_push.sh malformed
#
# Variabel opsional:
#   BUNDLE_ID=id.ac.polinema.campusNotify
#   DEVICE=<udid>          (default: simulator yang sedang boot)
#   SHOT=1                 ambil screenshot setelah mengirim
#   WAIT=3                 jeda sebelum screenshot (detik)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="${BUNDLE_ID:-id.ac.polinema.campusNotify}"
STATE="${1:-foreground}"

payload_for() {
  case "$1" in
    foreground | background | terminated) echo "announcement.apns" ;;
    data-only) echo "data_only.apns" ;;
    malformed) echo "malformed.apns" ;;
    *)
      echo "State tidak dikenal: $1" >&2
      echo "Pilihan: foreground | background | terminated | data-only | malformed" >&2
      exit 1
      ;;
  esac
}

if [[ -n "${DEVICE:-}" ]]; then
  UDID="$DEVICE"
else
  UDID="$(xcrun simctl list devices booted -j \
    | /usr/bin/python3 -c 'import json,sys; d=json.load(sys.stdin)["devices"]; print(next((x["udid"] for v in d.values() for x in v if x.get("state")=="Booted"), ""))')"
fi

if [[ -z "$UDID" ]]; then
  echo "Tidak ada simulator yang boot. Jalankan dulu:" >&2
  echo "  open -a Simulator" >&2
  exit 1
fi

PAYLOAD="$ROOT/tool/payloads/$(payload_for "$STATE")"

if [[ ! -f "$PAYLOAD" ]]; then
  echo "Payload tidak ditemukan: $PAYLOAD" >&2
  exit 1
fi

echo "Device   : $UDID"
echo "Bundle   : $BUNDLE_ID"
echo "State    : $STATE"
echo "Payload  : $(basename "$PAYLOAD")"

# State terminated butuh aplikasi benar-benar dimatikan lebih dulu, kalau
# tidak iOS menganggapnya background dan getInitialMessage tidak terpicu.
if [[ "$STATE" == "terminated" ]]; then
  echo "-> menghentikan aplikasi (simulate swipe-close)"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  sleep 1
fi

echo "-> mengirim payload"
xcrun simctl push "$UDID" "$BUNDLE_ID" "$PAYLOAD"

if [[ "${SHOT:-0}" == "1" ]]; then
  sleep "${WAIT:-3}"
  mkdir -p "$ROOT/screenshots"
  OUT="$ROOT/screenshots/$STATE.png"
  xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null
  echo "-> screenshot: screenshots/$STATE.png"
fi
