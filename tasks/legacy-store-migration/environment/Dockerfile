# Stage 1: build the legacy tool. Its source never reaches the final image.
FROM gcc:12.4.0-bookworm AS build
COPY oldbook-src/oldbook.c /src/oldbook.c
RUN gcc -O2 -static -Wl,--build-id=none -o /src/oldbook /src/oldbook.c && strip /src/oldbook

# Stage 2: the migration workstation.
FROM python:3.12-slim-bookworm
RUN pip install --no-cache-dir pytest==8.3.3
COPY --from=build /src/oldbook /app/legacy/oldbook
COPY app/ /app/
COPY oldbook-src/LICENSE /app/legacy/LICENSE
COPY data/legacy/ /data/legacy/
RUN chmod 0755 /app/legacy/oldbook && chmod -R a+rX /app /data && mkdir -p /app/out
ENV PATH="/app/legacy:${PATH}"
WORKDIR /app
