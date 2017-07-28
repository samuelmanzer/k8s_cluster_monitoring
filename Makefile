.PHONY: default container build tag push clean

default:
	@echo "Open Makefile to see available targets"

GOLANG_IMAGE=golang:1.8.3-jessie
CONTAINER_GOPATH=/go

REMOTE_REG ?= localhost:5000
WORKSPACE=$(CURDIR)/workspace

# kube-state-metrics executable - we stash the executable
# inside a customized docker image
KSM_URL=https://github.com/kubernetes/kube-state-metrics
KSM_IMPORT_PATH=k8s.io/kube-state-metrics
KSM_LOCAL_PATH=$(WORKSPACE)/src/$(KSM_IMPORT_PATH)
KSM_INSTALL_DIR=$(CONTAINER_GOPATH)/src/$(KSM_IMPORT_PATH)
KSM_IMAGE_NAME=kube-state-metrics:k8s_cluster_monitoring
KSM_REMOTE_TAG=$(REMOTE_REG)/$(KSM_IMAGE_NAME)
KSM_CUSTOM_DIR=ksm_custom
KSM_EXE=kube-state-metrics

# prometheus operator (for kube-prometheus)
PO_URL=https://github.com/coreos/prometheus-operator/archive/v0.11.0.tar.gz
PO_LOCAL_PATH=$(WORKSPACE)/src/prometheus-operator

$(KSM_LOCAL_PATH):
	mkdir -p $(WORKSPACE)/bin
	git clone -b master --single-branch --depth 1 $(KSM_URL) $(KSM_LOCAL_PATH)
	cd $(KSM_LOCAL_PATH) && git checkout bd7418a2a2e5a192f0d82e29302012580dd7dab5

$(PO_LOCAL_PATH):
	mkdir -p $(WORKSPACE)/bin
	wget $(PO_URL) -O $(WORKSPACE)/po.tar.gz && \
	mkdir -p $(PO_LOCAL_PATH) && \
	tar -xf $(WORKSPACE)/po.tar.gz -C $(PO_LOCAL_PATH) --strip-components 1

build: | $(KSM_LOCAL_PATH)
	docker run \
		-v $(WORKSPACE)/bin:/go/bin \
		-v $(WORKSPACE)/src:/go/src \
		-w $(KSM_INSTALL_DIR) \
		--rm $(GOLANG_IMAGE) \
		make build
	docker build -t $(KSM_IMAGE_NAME) $(KSM_LOCAL_PATH)

tag:
	docker tag $(KSM_IMAGE_NAME) $(KSM_REMOTE_TAG)

push: tag
	docker push $(KSM_REMOTE_TAG)

deploy: push | $(PO_LOCAL_PATH)
	# deploy kube-prometheus in default configuration
	cd $(PO_LOCAL_PATH)/contrib/kube-prometheus && \
	hack/cluster-monitoring/deploy
	kubectl --namespace=monitoring apply -f $(KSM_CUSTOM_DIR)/deployment.yaml
