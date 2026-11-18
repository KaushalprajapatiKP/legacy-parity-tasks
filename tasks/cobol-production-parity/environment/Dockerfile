# Toolchain shared by the production build stage and the agent image.
FROM debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc AS toolchain
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gnucobol3=3.1.2-5+b1 \
      python3=3.11.2-1+b1 \
      python3-pytest=7.2.1-2 \
 && rm -rf /var/lib/apt/lists/*

# Production 4.2 is compiled and stripped here; its source never reaches the final image.
FROM toolchain AS prodbuild
COPY prod42/ /build/
RUN cd /build \
 && cobc -x -fstatic-call -I copy -o billrun billrun.cbl lib/*.cbl \
 && strip billrun

FROM toolchain
COPY app/ /app/
COPY --from=prodbuild /build/billrun /app/prod/billrun
RUN chmod 0711 /app/prod/billrun && mkdir -p /app/build
WORKDIR /app
