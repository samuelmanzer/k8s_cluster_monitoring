.PHONY: default container build tag push clean

default:
	@echo "Open Makefile to see available targets"

GOLANG_IMAGE=golang:1.8.3-jessie
CONTAINER_GOPATH=/go

REMOTE_REG ?= localhost:5000

# Pull submodules automatically
GIT=git
GIT_SUBMODULES=$(shell sed -nr 's/path = +(.+)/\1\/.git/ p' .gitmodules | paste -s -)

$(GIT_SUBMODULES): %/.git: .gitmodules
	$(GIT) submodule init
	$(GIT) submodule update $*
	@touch $@

KSM_LOCAL_PATH=$(CURDIR)/submodules/kube-state-metrics
KSM_IMPORT_PATH=k8s.io/kube-state-metrics
KSM_INSTALL_DIR=$(CONTAINER_GOPATH)/src/$(KSM_IMPORT_PATH)
KSM_IMAGE_NAME=kube-state-metrics:k8s_cluster_monitoring
KSM_REMOTE_TAG=$(REMOTE_REG)/$(KSM_IMAGE_NAME)
KSM_CUSTOM_DIR=ksm_custom

PO_LOCAL_PATH=$(CURDIR)/submodules/prometheus-operator

build: $(GIT_SUBMODULES)
	docker run \
		-v $(KSM_LOCAL_PATH):$(KSM_INSTALL_DIR) \
		-w $(KSM_INSTALL_DIR) \
		--rm $(GOLANG_IMAGE) \
		make build
	docker build -t $(KSM_IMAGE_NAME) $(KSM_LOCAL_PATH)

tag: build
	docker tag $(KSM_IMAGE_NAME) $(KSM_REMOTE_TAG)

push: tag
	docker push $(KSM_REMOTE_TAG)

deploy: push
	# deploy kube-prometheus in default configuration
	cd $(PO_LOCAL_PATH)/contrib/kube-prometheus && \
	hack/cluster-monitoring/deploy
	kubectl --namespace=monitoring apply -f $(KSM_CUSTOM_DIR)/deployment.yaml
