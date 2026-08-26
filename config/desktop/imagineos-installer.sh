#!/usr/bin/env bash
set -uo pipefail

# Refresh partition devices before Calamares snapshots the available disks.
sudo udevadm trigger --subsystem-match=block --action=add || true
sudo partprobe || true
sudo udevadm settle --timeout=30 || true

exec pkexec calamares
