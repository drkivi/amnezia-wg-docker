## About This Project

This repository is a fork of [amnezia-wg-docker](https://github.com/yury-sannikov/amnezia-wg-docker), providing a MikroTik-compatible Docker image to run AmneziaWG on MikroTik routers.

Key features of this fork:
- Full **AmneziaWG 3.1** support — random packet trailers (`RandomTrailers`) and disableable cookie replies (`DisableCookies`), on top of AWG 3.0's header protection (`HeaderProtectionKey`), random content padding (`ContentPaddingAddition`), and randomizable handshake timings, and the `S3`/`S4`, `H1`–`H4` range format, and `I1`–`I5` obfuscation chain parameters from AmneziaWG 2.0
- Upgraded to Go 1.26.6 with all dependencies updated to latest secure versions
- Built from [drkivi/amneziawg-go](https://github.com/drkivi/amneziawg-go) — a maintained fork of [amnezia-vpn/amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go) with up-to-date modules
- Minimal runtime image based on Alpine 3.24

Currently supports: **ARMv7**, **ARM64**, and **MIPS**.

## Prerequisites

- Follow the [MikroTik guidelines](https://help.mikrotik.com/docs/display/ROS/Container) to enable container support on your MikroTik router.
- Install [Docker Buildx](https://github.com/docker/buildx)
- Ensure you have `make` installed on your build machine.

## Dependencies Used

```
go 1.26.6
    github.com/goccy/go-yaml v1.19.2
    go.uber.org/atomic v1.11.0
    golang.getoutline.org/sdk v0.0.23
    golang.getoutline.org/sdk/x v0.2.0
    golang.org/x/crypto v0.55.0
    golang.org/x/net v0.58.0
    golang.org/x/sys v0.47.0
    golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2
    gvisor.dev/gvisor v0.0.0-20260604230326-c7dbb92365cd
    github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572 // indirect
    github.com/google/btree v1.1.3 // indirect
    github.com/google/pprof v0.0.0-20211214055906-6f57359322fd // indirect
    github.com/gorilla/websocket v1.5.3 // indirect
    github.com/onsi/ginkgo/v2 v2.12.0 // indirect
    github.com/quic-go/qpack v0.5.1 // indirect
    github.com/quic-go/quic-go v0.48.1 // indirect
    github.com/shadowsocks/go-shadowsocks2 v0.1.5 // indirect
    github.com/stretchr/testify v1.11.1 // indirect
    go.uber.org/mock v0.4.0 // indirect
    golang.org/x/exp v0.0.0-20260813180055-c1d0aacb2297 // indirect
    golang.org/x/mobile v0.0.0-20260816165457-f98cc9b3c733 // indirect
    golang.org/x/mod v0.40.0 // indirect
    golang.org/x/sync v0.22.0 // indirect
    golang.org/x/text v0.41.0 // indirect
    golang.org/x/time v0.15.0 // indirect
    golang.org/x/tools v0.49.0 // indirect

    amneziawg-tools v3.1.20260812
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

## AmneziaWG 3.0 Parameters

AmneziaWG 3.0 (`AWG3`) adds header protection, random content padding, and randomizable handshake timings on top of AWG2. All of these are optional and default to the AWG2/WireGuard behavior when omitted:

| Parameter | Format | Description |
|-----------|--------|-------------|
| `HeaderProtectionKey` | key (string) | Encrypts the low-entropy header fields with ChaCha20, generated with `awg genkey`; requires all configured `S1`–`S4` to be at least 8 |
| `ContentPaddingAddition` | `value` or `min-max` | Extra random padding appended to transport packet content |
| `RekeyAfterTime` | `value` or `min-max` (seconds) | Time after which the client attempts a new handshake |
| `RekeyTimeout` | `value` or `min-max` (seconds) | Timeout after which a handshake attempt is retried |
| `RejectAfterTime` | `value` or `min-max` (seconds) | Time after which the client forces a new handshake and rejects further data on the old session |
| `KeepaliveTimeout` | `value` or `min-max` (seconds) | Time since the last sent data after which a keepalive is sent |
| `MaxHandshakeAttempts` | `value` or `min-max` | Maximum number of handshake retries before giving up |
| `PersistentKeepalive` (`[Peer]`) | `value` or `min-max` (seconds) | Persistent keepalive interval; now accepts a range |

> **Note:** As with the AWG2 parameters, `RekeyAfterTime`/`RekeyTimeout`/`RejectAfterTime`/`KeepaliveTimeout`/`MaxHandshakeAttempts` are client-side only and don't need to match on both peers. `HeaderProtectionKey` and `ContentPaddingAddition` are recommended to be set on both sides.

## AmneziaWG 3.1 Parameters

AmneziaWG 3.1 (`AWG3.1`) adds random packet trailers and the option to disable cookie replies, on top of AWG3.0/AWG2:

| Parameter | Format | Description |
|-----------|--------|-------------|
| `RandomTrailers` | `on` / `off` | Appends a random amount of extra bytes after every packet (handshake and transport alike), independent of `ContentPaddingAddition` |
| `DisableCookies` | `on` / `off` | Stops the interface from sending cookie replies to denied handshake attempts |

> **Note:** Both are client-side only and don't need to match on both peers.

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
