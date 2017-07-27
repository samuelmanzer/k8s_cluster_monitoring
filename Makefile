.PHONY: container build clean

GOLANG_IMAGE=golang:1.8.3-jessie
CONTAINER_GOPATH=/go

WORKSPACE_DIR=$(CURDIR)/kube-state-metrics/workspace
KSM_URL=https://github.com/kubernetes/kube-state-metrics/archive/v0.5.0.tar.gz
KSM_IMPORT_PATH=k8s.io/kube-state-metrics
KSM_LOCAL_PATH=$(WORKSPACE_DIR)/src/$(KSM_IMPORT_PATH)
KSM_INSTALL_DIR=$(CONTAINER_GOPATH)/src/$(KSM_IMPORT_PATH)

DOCKER_IMAGE_NAME=kube-state-metrics:k8s_cluster_monitoring

$(KSM_LOCAL_PATH):
	mkdir -p $(WORKSPACE_DIR)/bin
	wget $(KSM_URL) -O $(WORKSPACE_DIR)/ksm.tar.gz && \
	mkdir -p $(KSM_LOCAL_PATH) && \
	tar -xf $(WORKSPACE_DIR)/ksm.tar.gz -C $(KSM_LOCAL_PATH) --strip-components 1

build: | $(KSM_LOCAL_PATH)
	docker run \
		-v $(WORKSPACE_DIR)/bin:/go/bin \
		-v $(WORKSPACE_DIR)/src:/go/src \
		-w $(KSM_INSTALL_DIR) \
		--rm $(GOLANG_IMAGE) \
		make build
	docker build -f kube-state-metrics/Dockerfile -t $(DOCKER_IMAGE_NAME) .

clean:
	rm -rf $(WORKSPACE_DIR)
