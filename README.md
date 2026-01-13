# Bootc-based live ISOs

A PoC of building live ISOs from container images.

## Building ISOs
Build the container:

```
sudo just container bazzite
sudo just container kinoite
```

Then build the ISO:

```
sudo just iso bazzite
sudo just iso kinoite
```

## Building image-builder

For the time being, you need image-builder built with a custom images fork, see
https://github.com/osbuild/images/pull/2133:

```
git clone https://github.com/osbuild/image-builder-cli
cd image-builder-cli
go mod edit -replace github.com/osbuild/images=github.com/ondrejbudai/images@bootc-iso
go build ./cmd/image-buildercd ..
```

Then use it:

```
sudo just image-builder=./image-builder-cli/image-builder iso bazzite
```

## Status:
- builds
- boots
- flatpak embedding seems to work
- cannot install yet
- an unknown number of bugs exists
