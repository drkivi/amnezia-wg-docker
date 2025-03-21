awg-armv7:
	@if [ -d "amnezia-wg" ]; then \
		cd amnezia-wg && make clean && GOOS=linux GOARCH=arm7 make && cd ..; \
	else \
		echo "Directory amnezia-wg not found, skipping awg-armv7 build."; \
	fi

awg-arm64:
	@if [ -d "amnezia-wg" ]; then \
		cd amnezia-wg && make clean && GOOS=linux GOARCH=arm64 make && cd ..; \
	else \
		echo "Directory amnezia-wg not found, skipping awg-arm64 build."; \
	fi

awg-mips:
	@if [ -d "amnezia-wg" ]; then \
		cd amnezia-wg && make clean && GOOS=linux GOARCH=mipsle GOMIPS=softfloat make && cd ..; \
	else \
		echo "Directory amnezia-wg not found, skipping awg-mips build."; \
	fi

build-armv7: awg-armv7
	DOCKER_BUILDKIT=1 docker buildx build --no-cache --platform linux/arm/v7 --output=type=docker --tag amneziawg-for-armv7:latest .

build-arm64: awg-arm64
	DOCKER_BUILDKIT=1 docker buildx build --no-cache --platform linux/arm64 --output=type=docker --tag amneziawg-for-arm64:latest .

build-mips: awg-mips
	DOCKER_BUILDKIT=1 docker buildx build --no-cache --platform linux/mipsle --output=type=docker --tag amneziawg-for-mips:latest .

export-armv7: build-armv7
	docker save amneziawg-for-armv7:latest > amneziawg-for-armv7.tar

export-arm64: build-arm64
	docker save amneziawg-for-arm64:latest > amneziawg-for-arm64.tar

export-arm64: build-mips
	docker save amneziawg-for-mips:latest > amneziawg-for-mips.tar
