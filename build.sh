#!/bin/bash
VERSION="$(cat VERSION)"
ARCHES="$(cat ARCHES)"
REGISTRY="$(cat REGISTRY)"
IMAGE="$(cat IMAGE)"

for arch in $ARCHES; do
	docker build -t ${REGISTRY}${IMAGE}-${arch}:${VERSION} --build-arg VERSION=${VERSION} --build-arg IMAGE=${IMAGE} --build-arg ARCH=${arch} .
done

for arch in $ARCHES; do
	docker push ${REGISTRY}${IMAGE}-${arch}:${VERSION}
done

manifests=""
for arch in $ARCHES; do
	manifests+="${REGISTRY}${IMAGE}-${arch}:${VERSION} "
done

docker manifest create ${REGISTRY}${IMAGE}:${VERSION} $manifests
docker manifest push --purge ${REGISTRY}${IMAGE}:${VERSION}
