#!/usr/bin/env bash

# insert handler for entrypoints:
# - bash
# - wsadmin
# - dxtools
# - node
# - ...
#
# when done
# 1- copy the script in the app folder using Dockerfile
#       COPY --from=builder /opt/FY/thin-client/entrypoint.sh /app/
# 2- use this script as ENTRYPOINT in Dockerfile
#       ENTRYPOINT [ "app/entrypoint.sh" ]