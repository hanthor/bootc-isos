image-builder := "image-builder"
image-builder-dev := "image-builder-dev"

# Helper: returns "--bootc-installer-payload-ref <ref>" or "" if no payload_ref file
_payload_ref_flag target:
    @if [ -f "{{target}}/payload_ref" ]; then echo "--bootc-installer-payload-ref $(cat '{{target}}/payload_ref' | tr -d '[:space:]')"; fi

container target:
    podman build --cap-add sys_admin --security-opt label=disable -t {{target}}-installer ./{{target}}

iso target:
    {{image-builder}} build --bootc-ref localhost/{{target}}-installer --bootc-default-fs ext4 `just _payload_ref_flag {{target}}` bootc-generic-iso

# We need some patches that are not yet available upstream, so let's build a custom version.
build-image-builder:
    #!/bin/bash
    set -euo pipefail
    if [ -d image-builder-cli ]; then
        cd image-builder-cli
        git fetch origin
        git reset --hard cf20ed6a417c5e4dd195b34967cd2e4d5dc7272f
    else
        git clone https://github.com/osbuild/image-builder-cli.git
        cd image-builder-cli
        git reset --hard cf20ed6a417c5e4dd195b34967cd2e4d5dc7272f
    fi
    # if go is not in PATH, install via brew and use the full brew path
    if ! command -v go &> /dev/null; then
        if [ -d "/home/linuxbrew/.linuxbrew" ]; then
            GO_BIN="/home/linuxbrew/.linuxbrew/bin/go"
        else
            echo "go not found in PATH and /home/linuxbrew/.linuxbrew not found"
            exit 1
        fi
    else
        GO_BIN="go"
    fi
    $GO_BIN mod tidy
    $GO_BIN mod edit -replace github.com/osbuild/images=github.com/ondrejbudai/images@bootc-generic-iso-dev
    $GO_BIN get github.com/osbuild/blueprint@v1.22.0
    # GOPROXY=direct so we always fetch the latest bootc-generic-iso-dev branch
    GOPROXY=direct $GO_BIN mod tidy
    podman build --no-cache -t {{image-builder-dev}} .

iso-in-container target:
    just container {{target}}
    mkdir -p output
    podman run --rm --privileged \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        -v ./output:/output:Z \
        {{image-builder-dev}} \
        build --output-dir /output --bootc-ref containers-storage:localhost/{{target}}-installer --bootc-default-fs ext4 `just _payload_ref_flag {{target}}` bootc-generic-iso
