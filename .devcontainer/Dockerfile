# syntax=docker/dockerfile:1

FROM a1russell/container-image-dev-ubuntu

COPY .generated-init.env /etc/devcontainer-generated-init.env

RUN <<EOF
set -o errexit

. /etc/devcontainer-generated-init.env

if [ \
	-n "${CONTAINER_USERNAME}" -a \
	-n "${CONTAINER_UID}" -a \
	-n "${CONTAINER_GID}" -a \
	-n "${CONTAINER_DOCKER_GID}" \
]; then
	# Remove the `ubuntu` user.
	touch /var/mail/ubuntu
	chown ubuntu /var/mail/ubuntu
	userdel --remove ubuntu

	# Add the container user.
	addgroup --gid ${CONTAINER_GID} ${CONTAINER_USERNAME}
	adduser --disabled-password --uid ${CONTAINER_UID} --gid ${CONTAINER_GID} ${CONTAINER_USERNAME}

	# Set the docker group gid, and add the container user to the docker group.
	groupmod --gid ${CONTAINER_DOCKER_GID} docker
	usermod --append --groups docker ${CONTAINER_USERNAME}

	# Set up the .ssh directory for the container user.
	mkdir --parents "/home/${CONTAINER_USERNAME}/.ssh"
	chown "${CONTAINER_UID}:${CONTAINER_GID}" "/home/${CONTAINER_USERNAME}/.ssh"
	chmod 700 "/home/${CONTAINER_USERNAME}/.ssh"
fi

EOF

RUN rm /etc/devcontainer-generated-init.env
