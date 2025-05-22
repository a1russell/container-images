# syntax=docker/dockerfile:1

ARG git_plus_version=v0.4.10

FROM ubuntu:25.04 AS updated_ubuntu

RUN <<EOF
set -o errexit
apt-get --quiet update
apt-get dist-upgrade \
	--yes --no-install-recommends --option Dpkg::Options::='--force-confold'
apt-get --quiet --yes autoremove
apt-get clean
rm -r /var/lib/apt/lists/*
EOF

FROM updated_ubuntu AS updated_os_with_helper

COPY --chmod=755 files/usr/sbin/install_clean /usr/sbin/

FROM updated_os_with_helper AS minimal_base_image

RUN /usr/sbin/install_clean tini

FROM minimal_base_image AS dev_base_image

ENV LC_ALL=C.UTF-8

# For dev tools.
# ca-certificates: curl
# python3: git-plus, installed via uv
RUN /usr/sbin/install_clean \
	ca-certificates \
	python3

RUN /usr/sbin/install_clean \
	bzip2 \
	bzip2-doc \
	curl \
	dash \
	fzf \
	git \
	git-annex \
	git-doc \
	git-lfs \
	git-subrepo \
	gzip \
	jo \
	jq \
	just \
	less \
	man-db \
	micro \
	neovim \
	openssh-client \
	ripgrep \
	starship \
	unrar \
	xclip \
	xz-utils \
	yadm \
	zsh \
	zsh-doc

RUN chsh --shell /usr/bin/zsh root

RUN echo 'dash dash/sh boolean true' | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

RUN mkdir --parents /etc/entrypoint.d

RUN mkdir --mode=700 --parents /root/.ssh

RUN mkdir /root/.profile.d
RUN <<EOF
cat <<'EOF_' | sed --in-place '2r /dev/stdin' /root/.profile
if [ "$(ls /root/.profile.d/*.sh 2> /dev/null | wc --lines)" -gt '0' ]; then
	for f in /root/.profile.d/*.sh; do
		. "$f"
	done
fi

EOF_
EOF

ENV UV_TOOL_DIR=/usr/local/share/uv
ENV UV_TOOL_BIN_DIR=/usr/local/bin
RUN \
	curl --silent --show-error --fail --location https://astral.sh/uv/install.sh \
	| env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh
COPY files/root/.profile.d/uv.sh /root/.profile.d/uv.sh

ARG git_plus_version
RUN <<EOF
. /root/.profile.d/uv.sh
uv tool install --no-managed-python --no-cache git-plus@$git_plus_version
EOF

RUN mkdir --parents /etc/zsh/zshrc.d
COPY files/etc/zsh/zshrc.d/80--aliases.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc /tmp/
RUN <<EOF
echo >> /etc/zsh/zshrc
cat /tmp/zshrc >> /etc/zsh/zshrc
rm /tmp/zshrc
EOF

ENV ZNAP_HOME=/opt/zsh-snap
COPY files/opt/zsh-snap/ /opt/zsh-snap
COPY files/etc/zsh/zshrc.d/01--znap-repos.zsh /etc/zsh/zshrc.d/

COPY --chmod=755 files/sbin/entrypoint /sbin/
ENTRYPOINT ["/usr/bin/tini", "--", "/sbin/entrypoint"]
CMD ["/bin/zsh"]

FROM dev_base_image AS docker_cli

# Ensure that nsswitch.conf is set up for Go's "netgo" implementation (which Docker explicitly uses).
# - https://github.com/moby/moby/blob/v24.0.6/hack/make.sh#L111
# - https://github.com/golang/go/blob/go1.19.13/src/net/conf.go#L227-L303
RUN [ -e /etc/nsswitch.conf ] && grep '^hosts: \+files dns' /etc/nsswitch.conf

# Pre-add a "docker" group for socket usage.
RUN <<EOF
set -o errexit -o nounset -o xtrace
addgroup --system --gid 2375 docker
EOF

RUN <<EOF
set -o errexit
curl --silent --show-error --fail --location https://download.docker.com/linux/ubuntu/gpg \
	--output /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
	| tee /etc/apt/sources.list.d/docker.list > /dev/null
/usr/sbin/install_clean \
	docker-ce-cli \
	docker-buildx-plugin \
	docker-compose-plugin
EOF

# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   docker-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
RUN <<EOF
set -o errexit
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
mkdir --parents /certs/client
chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)
EOF

COPY --chmod=644 files/sbin/docker-entrypoint.sh /sbin/
COPY --chmod=755 files/sbin/docker-entrypoint /sbin/
RUN ln --symbolic /sbin/docker-entrypoint.sh /etc/entrypoint.d/docker.sh
