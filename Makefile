.PHONY: default
default: demo

.PHONY: demo
demo: supergraph docker-up query docker-down

.PHONY: demo-managed
demo-managed: introspect publish docker-up-managed query docker-down

.PHONY: docker-up
docker-up:
	docker-compose up -d
	@sleep 2
	@docker logs graph-router

.PHONY: query
query:
	@.scripts/query.sh

.PHONY: docker-down
docker-down:
	docker-compose down

.PHONY: supergraph
supergraph: introspect config compose

.PHONY: introspect
introspect:
	.scripts/introspect.sh

.PHONY: config
config:
	.scripts/config.sh > supergraph.yaml

.PHONY: compose
compose:
	rover supergraph compose --config ./supergraph.yaml > supergraph.graphql

.PHONY: graph-api-env
graph-api-env:
	@.scripts/graph-api-env.sh

.PHONY: docker-up-managed
docker-up-managed:
	docker-compose -f docker-compose.managed.yml up -d
	@sleep 2
	@docker logs graph-router

.PHONY: publish
publish:
	.scripts/publish.sh

.PHONY: check-products
check-products:
	.scripts/check-products.sh

.PHONY: check-all
check-all:
	.scripts/check-all.sh

.PHONY: local
local: supergraph install run

.PHONY: managed
managed: introspect publish install run-managed

.PHONY: run
run:
	node index.js supergraph.graphql

.PHONY: run-managed
run-managed:
	.scripts/run-managed.sh

.PHONY: install
install:
	npm install

.PHONY: docker
docker: docker-build docker-run

.PHONY: docker-build
docker-build: supergraph
	docker build -t my/supergraph-demo .

.PHONY: docker-run
docker-run:
	docker run --rm -d --name=gateway -p 4000:4000 my/supergraph-demo
	@sleep 2
	docker logs gateway

.PHONY: docker-stop
docker-stop:
	docker kill gateway

.PHONY: k8s-up
k8s-up:
	kind create cluster --image kindest/node:v1.19.7 --config=k8s/cluster.yaml --wait 5m
	kubectl apply -f https://github.com/datawire/ambassador-operator/releases/latest/download/ambassador-operator-crds.yaml
	kubectl apply -n ambassador -f https://github.com/datawire/ambassador-operator/releases/latest/download/ambassador-operator-kind.yaml
	kubectl wait --timeout=180s -n ambassador --for=condition=deployed ambassadorinstallations/ambassador
	kubectl apply -f k8s/router.yaml

.PHONY: k8s-query
k8s-query:
	.scripts/query.sh 80

.PHONY: k8s-smoke
k8s-smoke:
	.scripts/smoke.sh 80

.PHONY: k8s-down
k8s-down:
	kubectl delete -f k8s/router.yaml
	kind delete cluster

.PHONY: ci-local
ci-local:
	.scripts/ci-local.sh

.PHONY: ci-docker
ci-docker:
	.scripts/ci-docker.sh

.PHONY: smoke
smoke:
	@.scripts/smoke.sh

.PHONY: dep-act
dep-act:
	curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s v0.2.21

.PHONY: act
act:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/main.yml

.PHONY: act-all
act-all:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 --secret-file graph-api.env

.PHONY: act-checks
act-checks:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/checks.yml --secret-file graph-api.env --detect-event

.PHONY: act-publish
act-publish:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/publish.yml --secret-file graph-api.env

.PHONY: act-docker
act-docker:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/docker.yml --secret-file docker.secrets 

.PHONY: act-studio-build-hook
act-studio-build-hook:
	act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04 -W .github/workflows/studio-build-webhook.yml -s GITHUB_TOKEN --secret-file docker.secrets --detect-event
