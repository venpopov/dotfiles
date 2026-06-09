#!/bin/bash
# Keep the home NAS shares mounted via Tailscale, so they survive sleep,
# network changes, and travel. Public SMB (445) is firewall-closed, so we
# mount via the tailnet name (reachable from home AND remote).
# Run by the LaunchAgent com.venpopov.nas-automount (RunAtLoad + every 3 min).

NAS_HOST="ven-nas.taildf5375.ts.net"
SHARES=(home homes backup)   # NOT TMBackup — Time Machine manages that itself

log() { /usr/bin/logger -t nas-automount "$*"; }

# Only act if the NAS is actually reachable over SMB right now (avoids
# spurious unmount/mount churn when fully offline).
/usr/bin/nc -z -G3 "$NAS_HOST" 445 >/dev/null 2>&1 || exit 0

for share in "${SHARES[@]}"; do
  mp="/Volumes/$share"
  # Already mounted from the tailnet host? Leave it alone.
  if mount | grep -q "@${NAS_HOST}/${share} on ${mp} "; then
    continue
  fi
  # A stale mount of this share from a DIFFERENT host (e.g. the old public
  # name) is occupying the mountpoint — force-unmount it so we can remount clean.
  if mount | grep -q " ${mp} "; then
    /usr/sbin/diskutil unmount force "$mp" >/dev/null 2>&1 || /sbin/umount -f "$mp" >/dev/null 2>&1
    log "force-unmounted stale $mp"
  fi
  # Mount via AppleScript so it pulls credentials from Keychain silently
  # (after you've authenticated once and chosen 'remember password').
  /usr/bin/osascript -e "try" -e "mount volume \"smb://${NAS_HOST}/${share}\"" -e "end try" >/dev/null 2>&1 \
    && log "mounted $share via $NAS_HOST"
done
