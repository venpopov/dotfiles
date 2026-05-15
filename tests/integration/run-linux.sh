#!/usr/bin/env bash
# Build the Linux integration test image. All test steps run during the
# Docker build itself (see Dockerfile.ubuntu) — successful build = passing test.
#
# Called by `make test-integration` and by .github/workflows/ci.yml.
set -euo pipefail

cd "$(dirname "$0")/../.."  # repo root

IMAGE_TAG="${IMAGE_TAG:-dotfiles-integration}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH — install Docker (or use Colima/OrbStack on macOS)" >&2
  exit 1
fi

echo "==> docker build -> $IMAGE_TAG"
docker build \
  --file tests/integration/Dockerfile.ubuntu \
  --tag "$IMAGE_TAG" \
  .

echo "==> integration test passed"
