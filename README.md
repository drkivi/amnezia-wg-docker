## About This Project

This repository is a fork of [amnezia-wg-docker](https://github.com/yury-sannikov/amnezia-wg-docker), aiming to provide a Mikrotik-compatible Docker image to run Amnezia WG on Mikrotik routers.

The main focus of this fork is to enhance the security and stability of the build process by:
- Upgrading to the latest Go version (1.24.3)
- Updating all dependencies to their latest secure versions
- Using a modern builder image
- Minimizing vulnerabilities in the resulting Docker image

Currently, the project supports building for **ARMv7**, **ARM64**, and **MIPS** architectures.

## Prerequisites

- Follow the [Mikrotik guidelines](https://help.mikrotik.com/docs/display/ROS/Container) to enable container support on your Mikrotik router.
- Install [Docker Buildx](https://github.com/docker/buildx)
- Ensure you have `make` and `go` installed on your machine.

## Dependencies Used

This fork uses the following Go modules:

```
go 1.24.3
        github.com/tevino/abool/v2 v2.1.0
        golang.org/x/crypto v0.38.0
        golang.org/x/net v0.40.0
        golang.org/x/sys v0.33.0
        golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2
        gvisor.dev/gvisor v0.0.0-20250509002459-06cdc4c49840
        github.com/google/btree v1.1.3
        golang.org/x/time v0.11.0
```

## Building Docker Image

This project clones `amneziawg-go` from a customized and updated repository:
[drkivi/amneziawg-go](https://github.com/drkivi/amneziawg-go)

To build for **ARMv7**:
```sh
make build-armv7
```

To build for **ARM64**:
```sh
make build-arm64
```

To build for **MIPS**:
```sh
make build-mips
```

To export the built image:
```sh
make export-armv7
make export-arm64
make export-mips
```

You will get a `amneziawg-for-armv7.tar`, `amneziawg-for-arm64.tar`, or `amneziawg-for-mips.tar` archive ready to upload to your Mikrotik router.

Connection setup instructions for **ARMv7** and **ARM64** images are available on the Docker Hub page [ARMv7](https://hub.docker.com/r/drkivi/amneziawg-for-armv7) & [ARM64](https://hub.docker.com/r/drkivi/amneziawg-for-arm64).


## Sample wg0.conf

This is a general example of `wg0.conf` configuration. The only difference between Mikrotik and Raspberry Pi setups is the private gateway IP address used for routing:
- For **Mikrotik**, the default private IP is `192.168.88.1`
- For **Raspberry Pi (Docker)**, the default private IP is `172.17.0.1`

### General wg0.conf
```ini
[Interface]
Address = 10.8.1.2/32
DNS = [ip.of.awg.dns], 1.0.0.1
PrivateKey = YLeSX...Hsa3=
Jc = [Jc value]
Jmin = [Jmin value]
Jmax = [Jmax value]
S1 = [S1 value]
S2 = [S2 value]
H1 = [H1 value]
H2 = [H2 value]
H3 = [H3 value]
H4 = [H4 value]

Table = awg

PreUp = iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

PostUp = iptables -t nat -A POSTROUTING -o %i -j MASQUERADE
PostUp = ip route flush table awg
PostUp = ip rule add priority 300 from all iif eth0 lookup awg || true
PostUp = ip route add ip.of.awg.server via 192.168.88.1 dev eth0
PostUp = ip route replace default dev wg0

PostDown = iptables -t nat -D POSTROUTING -o %i -j MASQUERADE
PostDown = ip rule del from all iif eth0 lookup awg || true
PostDown = ip route replace default via 192.168.88.1 dev eth0
PostDown = ip route del ip.of.awg.server via 192.168.88.1 dev eth0

[Peer]
PublicKey = N22i......7C0i=
PresharedKey = Cjkx....pF+J=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ip.of.awg.server:port
PersistentKeepalive = 25
```

