# Sample page: build from the repository root.
#   docker build -f web/Dockerfile -t legacy-parity-web .
#   docker run --rm -p 8000:8000 legacy-parity-web
FROM python:3.12-slim-bookworm
WORKDIR /repo
COPY web/ web/
COPY trajectories/ trajectories/
COPY tasks/cobol-production-parity/task.toml tasks/cobol-production-parity/instruction.md tasks/cobol-production-parity/
COPY tasks/fortran-solver-parity/task.toml tasks/fortran-solver-parity/instruction.md tasks/fortran-solver-parity/
COPY tasks/legacy-store-migration/task.toml tasks/legacy-store-migration/instruction.md tasks/legacy-store-migration/
EXPOSE 8000
CMD ["python3", "web/server.py", "--host", "0.0.0.0", "--port", "8000"]
