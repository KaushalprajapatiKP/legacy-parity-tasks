# Toolchain shared by the production build stage and the work image.
FROM python:3.12.15-slim-bookworm AS toolchain
RUN apt-get update \
 && apt-get install -y --no-install-recommends gfortran-12=12.2.0-14+deb12u1 \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/bin/gfortran-12 /usr/bin/gfortran
RUN pip install --no-cache-dir pytest==8.3.4

# Production build of HYDRO 2.3. Its source never reaches the final image.
FROM toolchain AS prodbuild
COPY prod-src/ /build/
RUN cd /build && gfortran -O2 -o hydro *.f && strip hydro

# Work image: 1.8 source, documentation, and the stripped 2.3 executable.
FROM toolchain
COPY app/ /app/
COPY --from=prodbuild /build/hydro /app/prod/hydro
RUN chmod 0755 /app/prod/hydro
WORKDIR /app
