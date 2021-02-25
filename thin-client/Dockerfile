FROM fy-docker-private-nexus.factor-y.com/hcl/dx/core:v95_CF191_20201212-1421 AS builder

COPY thin-client /opt/FY/thin-client/

USER root
RUN cd /opt/FY/thin-client && ./generateThinClient.sh -w /opt/HCL/AppServer -p /opt/HCL/wp_profile

FROM centos:7

COPY --from=builder /opt/FY/thin-client/target /app

ENTRYPOINT [ "app/wsadmin.sh" ]
# -port 10033 -user wpsadmin -password wpsadmin -host 10.0.2.15