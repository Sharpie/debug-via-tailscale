#!/usr/bin/env bash
set -euo pipefail

TS_IP=$(tailscale ip -4)
TS_HOSTNAME=$(tailscale status --self --json | jq -r '.Self.DNSName' | sed 's/\.$//')

CONTINUE_FILE="${HOME}/continue"
TIME_LEFT=${SESSION_TIMEOUT:-21500}

echo ""
echo "========================================"
echo " Debug session started"
echo " Tailscale IP: ${TS_IP}"
echo " Hostname:     ${TS_HOSTNAME}"
echo "========================================"
echo ""

while [ ! -e "$CONTINUE_FILE" ] && [ "$TIME_LEFT" -gt 0 ]; do
  echo "########################################"
  echo "#"
  echo "# Connect via:"
  echo "#   ssh ${TS_HOSTNAME}"
  echo "#   ssh ${TS_IP}"
  echo "#"
  echo "# To end this session early, run:"
  echo "#   touch ~/continue"
  echo "#"
  printf '#  Time remaining: %dh:%02dm:%02ds\n' \
    $((TIME_LEFT/3600)) $((TIME_LEFT%3600/60)) $((TIME_LEFT%60))
  echo "#"
  echo "########################################"
  echo ""

  sleep 10
  TIME_LEFT=$((TIME_LEFT - 10))
done

if [ -e "$CONTINUE_FILE" ]; then
  echo "Continue file detected. Ending debug session."
else
  echo "Timeout reached. Ending debug session."
fi
