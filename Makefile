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

build/%: src/coredns/core/dnsserver/zdirectives.go
	cd src/coredns; $(SYSTEM) go build -v -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$$(git describe --dirty --always)" -o $(TOP)/$@/coredns

.PHONY: build
build:
	$(MAKE) build/linux-arm64 SYSTEM="GOOS=linux GOARCH=arm64"
	$(MAKE) build/linux-amd64 SYSTEM="GOOS=linux GOARCH=amd64"
	$(MAKE) build/darwin-amd64 SYSTEM="GOOS=darwin GOARCH=amd64"
	$(MAKE) build/darwin-arm64 SYSTEM="GOOS=darwin GOARCH=arm64"


build/out/%.tar.gz: build/%
	tar -cvf

.PHONY: clean/src
clean/src:
	rm -rf src

.PHONY: clean/build
clean/build:
	rm -rf build

.PHONY: clean
clean: clean/build clean/src
