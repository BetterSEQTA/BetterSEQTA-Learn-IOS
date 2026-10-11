# Device deploy (Windows + WSL + xtool)

## What `deploy-iphone.ps1` does

| Step | Meaning |
|------|---------|
| Sync | `rsync` app sources to `~/BetterSEQTA-Learn-IOS-build` (ext4; excludes Android clones) |
| Build | `xtool dev build` using `xtool.device.yml` (no widget; signing workaround) |
| Install unpack / prepare / provision / sign / package | Build signed `.app` and zip payload on Linux |
| **Connecting** | Push package to the iPhone over **USB lockdown** (usbmux). This is where USB passthrough often hangs |

If **Connecting** sits at 100% with no finish, WSL usually lost USB (`LockdownClient.Error.muxError`).

## Fix USB connect

1. Kill stuck installs in WSL: `pkill -f 'xtool install'` (or close the PowerShell window and open a new one).
2. Windows: `.\scripts\attach-iphone-usb.ps1` (approve UAC for `bind --force` if needed).
3. iPhone: unlocked, **Trust** this PC, **Developer Mode** on.
4. Verify: `wsl -d Ubuntu-24.04 -- xtool devices` → must show `Aden's iPhone [usb]` with a UDID (no `muxError`).
5. Retry: `.\scripts\deploy-iphone.ps1`

## Wi‑Fi install (optional)

If the phone is paired for network debugging:

```powershell
wsl -d Ubuntu-24.04 -- bash -lc "INSTALL_TRANSPORT=--network /mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS/scripts/deploy-iphone.sh"
```

## WSL packages

```bash
sudo apt-get install -y zip unzip
```

`unzip` was required during `xtool setup`; `zip` is required for install packaging.
