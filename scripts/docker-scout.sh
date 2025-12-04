#!/bin/bash
set -euo pipefail

IMAGE="my-next-ci-app:latest"
CONTAINER="my-next-ci-app"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker build -t "$IMAGE" .

docker scout cves "$IMAGE" --output ./vulns.report
docker scout cves "$IMAGE" --only-severity high --exit-code

docker run -d --name "$CONTAINER" -p 3000:3000 "$IMAGE"
