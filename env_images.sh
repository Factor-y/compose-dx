#!/bin/sh

# CF191 Images IDs

if [ -n $DX_VERSION ]; then
    echo "Setting DX version to latest"
    DX_VERSION=CF191
fi

echo "Setup images for: $DX_VERSION"
#
# CF191 image tags
#
if [ "$DX_VERSION" = "CF191" ]; then

    export CORE_IMAGE=hcl/dx/core:v95_CF191_20201212-1421
    export RING_IMAGE=hcl/dx/ringapi:v1.5.0_20201211-2200
fi

# Work in progress, to be completed
# export DXOPERATOR_IMAGE=hcl/dx/cloud-operator:v95_CF191_20201214-1527

echo "DX Core:\t$CORE_IMAGE"
echo "DX Ring API:\t$RING_IMAGE"