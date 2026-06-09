build-armv7:
	DOCKER_BUILDKIT=1 docker buildx build --builder awg-builder --no-cache --platform linux/arm/v7 --output=type=docker --tag amneziawg-for-armv7:latest .

build-arm64:
	DOCKER_BUILDKIT=1 docker buildx build --builder awg-builder --no-cache --platform linux/arm64 --output=type=docker --tag amneziawg-for-arm64:latest .

build-mips:
	DOCKER_BUILDKIT=1 docker buildx build --builder awg-builder --no-cache --platform linux/mipsle --output=type=docker --tag amneziawg-for-mips:latest .

export-armv7: build-armv7
	docker save amneziawg-for-armv7:latest > amneziawg-for-armv7.tar

export-arm64: build-arm64
	docker save amneziawg-for-arm64:latest > amneziawg-for-arm64.tar

export-mips: build-mips
	docker save amneziawg-for-mips:latest > amneziawg-for-mips.tar
