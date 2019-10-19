#!/bin/bash
VERSION="$(cat VERSION)"
ARCHES="$(cat ARCHES)"
REGISTRY="$(cat REGISTRY)"
IMAGE="$(cat IMAGE)"
DOCKERHUB=yhaenggi/

for arch in $ARCHES; do
	docker tag ${REGISTRY}${IMAGE}-${arch}:${VERSION} ${DOCKERHUB}${IMAGE}-${arch}:${VERSION}
done

REGISTRY=${DOCKERHUB}
for arch in $ARCHES; do
	docker push ${REGISTRY}${IMAGE}-${arch}:${VERSION}
done

manifests=""
for arch in $ARCHES; do
	manifests+="${REGISTRY}${IMAGE}-${arch}:${VERSION} "
done

docker manifest create ${REGISTRY}${IMAGE}:${VERSION} $manifests
docker manifest push --purge ${REGISTRY}${IMAGE}:${VERSION}
