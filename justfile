image-builder := "image-builder"
image-builder-dev := "image-builder-dev"

# Helper: returns "--bootc-installer-payload-ref <ref>" or "" if no payload_ref file
_payload_ref_flag target:
    @echo '{{ if path_exists(target / "payload_ref") == "true" { "--bootc-installer-payload-ref " + trim(read(target / "payload_ref")) } else { "" } }}'

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
        git reset --hard origin/main
    else
        git clone https://github.com/osbuild/image-builder-cli.git
        cd image-builder-cli
    fi
    go mod tidy
    go mod edit -replace github.com/osbuild/images=github.com/ondrejbudai/images@bootc-generic-iso-dev
    # GOPROXY=direct so we always fetch the latest bootc-generic-iso-dev branch
    GOPROXY=direct go mod tidy
    podman build -t {{image-builder-dev}} .

iso-in-container target:
    mkdir -p output
    podman run --rm --privileged \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        -v ./output:/output:Z \
        {{image-builder-dev}} \
        build --output-dir /output --bootc-ref localhost/{{target}}-installer --bootc-default-fs ext4 `just _payload_ref_flag {{target}}` bootc-generic-iso
