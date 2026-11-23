# Build results - 2026-11-24

Upstream: `https://github.com/MeIsReallyBa/padavan-4.4.git`

Pinned commit: `10893720a7a620869c920a8c6bde41eb28df573b`

Build host: WSL Debian 13 `king` (12 vCPU, 16 GiB), `gcc 14.2.0-19`.

## Artifacts

| Profile | File | Size | SHA256 |
|---|---|---|---|
| 1000 MHz overclock | `RM2100_4.4.198.9-100-1000mhz.trx` | 10,320,470 | `5eeb1cf1646434bab01ca3ad1dd578dc55def5abcb5c4fb512053bbe3ec32812` |
| 880 MHz control | `RM2100_4.4.198.9-100-880mhz.trx` | 10,320,606 | `6bd9beb04dcf8852d465c091f8d8735620088f1acc111d9b74fd2c0e72bd93d6` |

The two profiles differ only in the CPU clock policy:

- `1000mhz`: `CONFIG_MT7621_OC=y`, `CONFIG_MT7621_CPU_FREQ="0x312"`
- `880mhz`: `# CONFIG_MT7621_OC is not set`

The kernel config diff between the two builds contains only the
`CONFIG_MT7621_OC` line; the firmware config diff contains only
`CONFIG_FIRMWARE_INCLUDE_OC` and `CONFIG_TOOLCHAIN_DIR`.

## Verification

`scripts/verify-image.sh` passed for both images. It confirmed:

- SQM UI and `sch_cake.ko`, `tc`, `ipset`
- DDNS UI with Cloudflare provider and `inadyn`
- WAN `sfe_enable` switch
- WireGuard (`wg`), ZeroTier (`zerotier-one`), Aliyun DDNS
- `tcpdump`, OpenSSH, IPv6
- `CONFIG_NET_SCH_CAKE=m`, `CONFIG_IFB=y`
- `CONFIG_MT7621_OC=y` + `CONFIG_MT7621_CPU_FREQ=0x312` for 1000 MHz
- `CONFIG_MT7621_OC` disabled for the 880 MHz control

QEMU user-mode smoke test on the 1000 MHz image:

```text
busybox echo QEMU_OK          -> QEMU_OK
tc -V                         -> iproute2-5.12.0
inadyn --version              -> 2.8.1
wg --version                  -> wireguard-tools v1.0.20210914
tcpdump --version             -> 4.9.2 / libpcap 1.9.1
```

## Build environment incident

The NAT LXC pool's six public entries all returned `NOBANNER` during the
build window. Two builds were started on `lxc3`/`lxc4` with the same pinned
source and profiles, but the pool became unreachable before their artifacts
could be retrieved. The final artifacts above were built on the local WSL
host with the same repository, profiles and source archive. No main-router
write or flash was performed.

## Risk notes

- **No hardware validation was performed.** The images were not flashed.
  `1000 MHz` is an overclock: test it on a spare RM2100, confirm
  `dmesg | grep "CPU Clock"`, and watch temperature/stability before
  considering it for 24/7 use. The `880 MHz` image is the safe control.
- Padavan ships with `admin` / `admin`; change it immediately after flashing.
- Do not restore a 3.4 nvram backup onto a 4.4 image. Reconfigure WAN/LAN/WiFi
  and DDNS manually.
- Keep SQM and SFE mutually exclusive when accurate shaping matters:
  SFE for maximum throughput, SQM (cake/fq_codel) for bufferbloat control.

