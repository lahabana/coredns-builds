# coredns-builds

[coredns](https://github.com/coredns/coredns) Builds specific to [Kuma](https://github.com/kumahq/kuma).

## Making dependabot work 

To be able to rely on dependabot we have a `go mod` in the root with the 2 dependencies we have. Because `go mod tidy` will remove
unused dependencies we have an `internal` package that imports these 2 dependencies.

## Building

You can build any version with `make build/<name>/coredns`.
In practice this is all done in a github action.
