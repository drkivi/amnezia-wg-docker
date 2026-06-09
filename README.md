## About This Project

This repository is a fork of [amnezia-wg-docker](https://github.com/yury-sannikov/amnezia-wg-docker), providing a MikroTik-compatible Docker image to run AmneziaWG on MikroTik routers.

Key features of this fork:
- Full **AmneziaWG 2.0** support — `S3`/`S4`, `H1`–`H4` range format, and `I1`–`I5` obfuscation chain parameters
- Upgraded to Go 1.26.4 with all dependencies updated to latest secure versions
- Built from [drkivi/amneziawg-go](https://github.com/drkivi/amneziawg-go) — a maintained fork of [amnezia-vpn/amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go) with up-to-date modules
- Minimal runtime image based on Alpine 3.23

Currently supports: **ARMv7**, **ARM64**, and **MIPS**.

## Prerequisites

- Follow the [MikroTik guidelines](https://help.mikrotik.com/docs/display/ROS/Container) to enable container support on your MikroTik router.
- Install [Docker Buildx](https://github.com/docker/buildx)
- Ensure you have `make` installed on your build machine.

## Dependencies Used

```
go 1.26.4
    github.com/Jigsaw-Code/outline-sdk v0.0.20
    github.com/Jigsaw-Code/outline-sdk/x v0.0.8
    github.com/goccy/go-yaml v1.19.2
    go.uber.org/atomic v1.11.0
    golang.org/x/crypto v0.53.0
    golang.org/x/net v0.55.0
    golang.org/x/sys v0.46.0
    golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2
    gvisor.dev/gvisor v0.0.0-20260604230326-c7dbb92365cd
    github.com/google/btree v1.1.3 // indirect
    github.com/gorilla/websocket v1.5.3 // indirect
    github.com/shadowsocks/go-shadowsocks2 v0.1.5 // indirect
    github.com/stretchr/testify v1.11.1 // indirect
    golang.org/x/exp v0.0.0-20260603202125-055de637280b // indirect
    golang.org/x/mobile v0.0.0-20260602190626-68735029466e // indirect
    golang.org/x/mod v0.37.0 // indirect
    golang.org/x/sync v0.21.0 // indirect
    golang.org/x/time v0.15.0 // indirect
    golang.org/x/tools v0.45.0 // indirect

    AWG_Tools v1.0.20260223
```

## Building Docker Image

To build and export a ready-to-upload `.tar` archive:

```sh
make export-armv7    # → amneziawg-for-armv7.tar
make export-arm64    # → amneziawg-for-arm64.tar
make export-mips     # → amneziawg-for-mips.tar
```

To build without exporting:

```sh
make build-armv7
make build-arm64
make build-mips
```

The resulting archive can be uploaded directly to your MikroTik router as a container image.

## AmneziaWG 2.0 Parameters

AmneziaWG 2.0 (`AWG2`) extends the original obfuscation parameter set. The full list of supported `[Interface]` parameters:

| Parameter | Format | Description |
|-----------|--------|-------------|
| `Jc` | integer | Number of junk packets sent before handshake |
| `Jmin` | integer | Min junk packet size (bytes) |
| `Jmax` | integer | Max junk packet size (bytes) |
| `S1` | integer | Init packet header size offset |
| `S2` | integer | Response packet header size offset |
| `S3` | integer | Additional size offset (AWG2) |
| `S4` | integer | Additional size offset (AWG2) |
| `H1`–`H4` | `value` or `min-max` | Handshake field values; AWG2 servers send ranges |
| `I1`–`I5` | `<r N><b 0x...>` | Obfuscation chain blocks (AWG2, omit lines that have no value) |

> **Important:** Do not include `I2`–`I5` lines with empty values. The `awg setconf` tool cannot parse empty parameters and will fail to bring up the tunnel.

## Sample wg0.conf

The routing setup differs by platform:

| Platform | Container interface | Default gateway |
|----------|---------------------|-----------------|
| MikroTik container | `veth1` | container veth gateway (e.g. `172.17.0.1`) |
| Raspberry Pi (Docker) | `eth0` | Docker bridge gateway (e.g. `172.17.0.1`) |

### MikroTik

```ini
[Interface]
Address = 10.8.1.2/32
DNS = ip.of.awg.dns, 1.0.0.1
PrivateKey = <your private key>
Jc = 5
Jmin = 10
Jmax = 50
S1 = 144
S2 = 21
S3 = 11
S4 = 7
H1 = 1950235005-1959490680
H2 = 1991067541-2020853453
H3 = 2083726449-2121690785
H4 = 2135625622-2139052227
I1 = <r 2><b 0x...>

Table = awg

PreUp = resolvconf -u 2>/dev/null || true
PreUp = iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

PostUp = iptables -t nat -A POSTROUTING -o %i -j MASQUERADE
PostUp = ip route flush table awg
PostUp = ip rule add priority 300 from all iif eth0 lookup awg || true
PostUp = ip route add ip.of.awg.server via <veth-gateway> dev veth1
PostUp = ip route replace default dev wg0

PostDown = iptables -t nat -D POSTROUTING -o %i -j MASQUERADE
PostDown = ip rule del from all iif eth0 lookup awg || true
PostDown = ip route replace default via <veth-gateway> dev veth1
PostDown = ip route del ip.of.awg.server via <veth-gateway> dev veth1

[Peer]
PublicKey = <server public key>
PresharedKey = <preshared key>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ip.of.awg.server:port
PersistentKeepalive = 25
```

Replace `<veth-gateway>` with the default gateway of the container's `veth1` interface (visible via `ip route` inside the container, typically the IP assigned to the MikroTik veth interface on the router side).

The `PreUp = resolvconf -u` line is required on MikroTik containers to avoid a signature mismatch error when `awg-quick` tries to update `/etc/resolv.conf`.

### Raspberry Pi (Docker)

```ini
[Interface]
Address = 10.8.1.2/32
DNS = ip.of.awg.dns, 1.0.0.1
PrivateKey = <your private key>
Jc = 5
Jmin = 10
Jmax = 50
S1 = 144
S2 = 21
S3 = 11
S4 = 7
H1 = 1950235005-1959490680
H2 = 1991067541-2020853453
H3 = 2083726449-2121690785
H4 = 2135625622-2139052227
I1 = <r 2><b 0x...>

Table = awg

PreUp = iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

PostUp = iptables -t nat -A POSTROUTING -o %i -j MASQUERADE
PostUp = ip route flush table awg
PostUp = ip rule add priority 300 from all iif eth0 lookup awg || true
PostUp = ip route add ip.of.awg.server via 172.17.0.1 dev eth0
PostUp = ip route replace default dev wg0

PostDown = iptables -t nat -D POSTROUTING -o %i -j MASQUERADE
PostDown = ip rule del from all iif eth0 lookup awg || true
PostDown = ip route replace default via 172.17.0.1 dev eth0
PostDown = ip route del ip.of.awg.server via 172.17.0.1 dev eth0

[Peer]
PublicKey = <server public key>
PresharedKey = <preshared key>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ip.of.awg.server:port
PersistentKeepalive = 25
```
