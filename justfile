build-dev-ubuntu:
	docker build --target dev_base_image --tag a1russell/dev-ubuntu src/

build-container-image-dev-ubuntu:
	docker build --target docker_cli --tag a1russell/container-image-dev-ubuntu src/
