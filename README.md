# RM2100 Padavan 4.4 main-router build

Reproducible build profile for the Redmi AC2100 / RM2100 (MT7621) based on
[MeIsReallyBa/padavan-4.4](https://github.com/MeIsReallyBa/padavan-4.4).

The profile keeps the router focused on routing, QoS, DDNS and remote access:

- SQM with `fq_codel` / `cake`
- shortcut-fe (`SFE`) / hardware NAT toggles in the WAN page
- IPv6 + IPSET
- WireGuard + ZeroTier
- built-in DDNS (`inadyn`) + Aliyun DDNS
- curl / OpenSSL / HTTPS web UI
- tcpdump / mtr / iperf3 / socat / htop
- OpenSSH + SFTP

It deliberately excludes AdGuardHome, Clash, Hysteria, Tailscale, NetBird,
frp/ngrok/nps, SoftEther, OpenVPN, aria2/transmission, koolproxy/ADM/adbyby
and the old transparent-proxy stack. Those belong on a VPS/NAS, not on the
main router.

## Profiles

| Profile | CPU clock | Purpose |
|---|---|---|
| `1000mhz` | forced 1000 MHz (`CONFIG_FIRMWARE_MT7621_OC="0x312"`) | requested overclock build; can raise power/heat and reduce stability margin |
| `880mhz` | bootloader clock, OC disabled | safe A/B control |

The 1000 MHz build is **not** validated on the main router. Treat it as an
experimental image until it has passed a spare-device soak test.

## Build

On a Debian 12/13 host:

```bash
sudo ./scripts/install-deps.sh
./scripts/build.sh 1000mhz
./scripts/build.sh 880mhz
```

The script clones the pinned upstream commit into `work/`, renders the profile,
downloads the hanwckf MIPS toolchain, builds with `fakeroot
./build_firmware_modify RM2100 custom`, then runs static image checks.

Artifacts land in `out/<profile>/`:

- `*.trx`
- `SHA256SUMS`
- `verify.txt`
- `build-meta.txt`
- `firmware.config`
- `kernel-4.4.config`

## Security notes

- Padavan builds ship with the default `admin` / `admin` web login. Change it
  immediately after flashing.
- The build repository contains no credentials or keys.
- Do not restore a 3.4 nvram backup onto a 4.4 image. Reconfigure WAN/LAN/WiFi
  and DDNS manually.

