GO_BUILD_COREDNS := GOOS=${GOOS} GOARCH=${GOARCH} CGO_ENABLED=${CGO_ENABLED} go build -v

COREDNS_REPO ?= https://github.com/coredns/coredns
COREDNS_VERSION ?= $(shell go  list -m  -f '{{.Version}}' github.com/coredns/coredns)
TOP := $(shell pwd)

src/coredns: go.mod
	rm -rf $@
	git clone --branch $(COREDNS_VERSION) --depth 1 $(COREDNS_REPO) $@
	cp plugin.cfg $@/plugin.cfg

	cd $@

src/coredns/core/dnsserver/zdirectives.go: src/coredns plugin.cfg
	cd src/coredns; git reset --hard
	cp plugin.cfg src/coredns/plugin.cfg
	cd src/coredns \
		&& go get github.com/coredns/alternate@$(shell go list -m -f '{{.Version}}' github.com/coredns/alternate) \
		&& go generate coredns.go

build/out/coredns_$(COREDNS_VERSION)_%.tar.gz: build/bin/%/coredns
	mkdir -p build/out
ifeq ($(shell uname),Darwin)
	tar --numeric-owner --strip-components=3 -czvf $@ $<
else
	tar --mtime='1970-01-01 00:00:00' -C $(dir $<) --sort=name --owner=root:0 --group=root:0 --numeric-owner -czvf $@ coredns
endif
	shasum -a 256 $@ > $@.sha256

build/bin/%/coredns: src/coredns/core/dnsserver/zdirectives.go
	cd src/coredns; $(SYSTEM) go build -v -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$$(git describe --dirty --always)" -o $(TOP)/$@

.PHONY: tar
tar:
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_linux_arm64.tar.gz SYSTEM="GOOS=linux GOARCH=arm64"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_linux_amd64.tar.gz SYSTEM="GOOS=linux GOARCH=amd64"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_darwin_arm64.tar.gz SYSTEM="GOOS=darwin GOARCH=arm64"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_darwin_amd64.tar.gz SYSTEM="GOOS=darwin GOARCH=amd64"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_linux_arm64+fips.tar.gz SYSTEM="GOOS=linux GOARCH=arm64 GOEXPERIMENT=boringcrypto"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_linux_amd64+fips.tar.gz SYSTEM="GOOS=linux GOARCH=amd64 GOEXPERIMENT=boringcrypto"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_darwin_arm64+fips.tar.gz SYSTEM="GOOS=darwin GOARCH=arm64 GOEXPERIMENT=boringcrypto"
	$(MAKE) build/out/coredns_$(COREDNS_VERSION)_darwin_amd64+fips.tar.gz SYSTEM="GOOS=darwin GOARCH=amd64 GOEXPERIMENT=boringcrypto"

.PHONY: clean/src
clean/src:
	rm -rf src

.PHONY: clean/build
clean/build:
	rm -rf build

.PHONY: clean/build/out
clean/build/out:
	rm -rf build/out

.PHONY: clean
clean: clean/build clean/src
