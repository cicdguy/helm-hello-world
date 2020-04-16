# Vars
APP_NAME = flask-hello-world
DOCKER_IMAGE = ${DOCKERHUB_USER}/${APP_NAME}
APP_VERSION = $(shell grep appVersion helm/Chart.yaml | awk '{print $$NF}')
CHART_VERSION = $(shell grep version helm/Chart.yaml | awk '{print $$NF}')
K8S_NAMESPACE = flask-hello-world
APP_INTERNAL_PORT = $(shell grep FLASK_PORT helm/values.yaml | awk '{print $$NF}')
LOCALHOST_PORT = 5000

.PHONY: list docker/build docker/run helm/build helm/lint helm/deploy clean
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

all: docker/build

# Docker
docker/build:
	@echo "Building Docker image"
	docker build --rm --tag $(DOCKER_IMAGE):$(APP_VERSION) .
	docker tag $(DOCKER_IMAGE):$(APP_VERSION) $(DOCKER_IMAGE):latest

docker/run: docker/build
	@echo "Running app locally"
	docker run --rm -p $(LOCALHOST_PORT):$(APP_INTERNAL_PORT) -e FLASK_PORT=$(APP_INTERNAL_PORT) ${DOCKER_IMAGE}:$(APP_VERSION)

docker/push: docker/build
	@echo "Pushing Docker image to DockerHub"
	docker login --username "${DOCKERHUB_USER}" --password "${DOCKERHUB_PASSWORD}"
	docker push $(DOCKER_IMAGE):$(APP_VERSION)
	docker push $(DOCKER_IMAGE):latest

# Helm/K8s deployments
helm/build:
	@echo "Building helm chart"
	helm package helm --app-version $(CHART_VERSION)

helm/lint: helm/build
	@echo "Linting Helm chart"
	helm lint $(APP_NAME)-$(CHART_VERSION).tgz

helm/undeploy:
	@echo "Uninstalling Helm releases from k8s cluster"
	helm uninstall --namespace $(K8S_NAMESPACE) \
		$(APP_NAME)-latest

helm/deploy: helm/lint
	@echo "Deploying Helm Chart"
	helm install --replace --namespace $(K8S_NAMESPACE) \
		--set image.repository=$(DOCKER_IMAGE) \
		$(APP_NAME)-latest $(APP_NAME)-$(CHART_VERSION).tgz

# Misc
clean:
	@echo "Cleaning build artifacts"
	rm -rf dist *.egg-info build .pytest_cache *tgz
	find . -type d -name "__pycache__" | xargs rm -rf {} \;

proxy:
	@echo "Proxy command to access service on http://localhost:$(LOCALHOST_PORT)/"
	@echo "--------------------------------------"
	@echo "kubectl port-forward -n $(K8S_NAMESPACE) pods/`kubectl get pods -n $(K8S_NAMESPACE) --no-headers=true | awk '{print $$1}'` $(LOCALHOST_PORT):$(APP_INTERNAL_PORT)"