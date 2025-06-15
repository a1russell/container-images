build-dev-ubuntu:
	docker build --target dev_base_image --tag a1russell/dev-ubuntu src/

build-container-image-dev-ubuntu:
	docker build --target docker_cli --tag a1russell/container-image-dev-ubuntu src/

build-dind-ubuntu:
	docker build --target docker --tag a1russell/dind-ubuntu src/

build-node-app-dev-ubuntu:
	docker build --target node --tag a1russell/node-app-dev-ubuntu src/

build-k8s-app-dev-ubuntu:
	docker build --target k8s --tag a1russell/k8s-app-dev-ubuntu src/
