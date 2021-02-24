#!/bin/sh

echo "[Compose-dx - sdk] Initializing Docker HCL DX environment"
. ./env_default.sh

if [ -f env_local.sh ]; then
    echo "[Compose-dx - local] Applying local project overrides"
    . ./env_local.sh
fi

echo "[Compose-dx - sdk] Initializing Docker images variables "
. ./env_images.sh
