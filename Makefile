.PHONY: default container build tag push clean

default:
	@echo "Open Makefile to see available targets"

# Pull submodules automatically
GIT=git
GIT_SUBMODULES=$(shell sed -nr 's/path = +(.+)/\1\/.git/ p' .gitmodules | paste -s -)

$(GIT_SUBMODULES): %/.git: .gitmodules
	$(GIT) submodule init
	$(GIT) submodule update $*
	@touch $@

KSM_CUSTOM_DIR=ksm_custom

PO_LOCAL_PATH=$(CURDIR)/submodules/prometheus-operator

deploy:
	# deploy kube-prometheus in default configuration
	cd $(PO_LOCAL_PATH)/contrib/kube-prometheus && \
	hack/cluster-monitoring/deploy
	# Patch the kube-state-metrics deployment to use newer version
	kubectl --namespace=monitoring apply -f $(KSM_CUSTOM_DIR)/deployment.yaml
teardown:
	cd $(PO_LOCAL_PATH)/contrib/kube-prometheus && \
	hack/cluster-monitoring/teardown
