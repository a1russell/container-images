# syntax=docker/dockerfile:1

ARG git_plus_version=v0.4.10
ARG starship_version=v1.23.0
ARG k0s_version=v1.33.1+k0s.1
ARG k0sctl_version=v0.25.1
ARG skaffold_version=v2.16.0
ARG kustomize_version=v5.6.0
ARG k9s_version=v0.50.6

FROM ubuntu:24.04 AS updated_ubuntu

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

RUN printf "y\n" | unminimize

# Installation helper tools.
# ca-certificates: for curl
# curl: for various installations, e.g. mise
# gpg: deb repos, e.g. mise
# jq: for custom `mise_link_system_tools` script and potentially others
RUN /usr/sbin/install_clean \
	ca-certificates \
	curl \
	gpg \
	jq

# For dev tools.
# gpg-agent: mise
RUN /usr/sbin/install_clean \
	gpg-agent

# Dev tools.
# Duplicates from above steps are acceptable.
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
	unrar \
	unzip \
	xclip \
	xz-utils \
	yadm \
	zsh \
	zsh-doc

RUN chsh --shell /usr/bin/zsh root

RUN echo 'dash dash/sh boolean true' | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

RUN mkdir --parents /etc/entrypoint.d

RUN mkdir --parents /etc/zsh/zprofile.d
RUN <<EOF
cat <<'EOF_' >> /etc/zsh/zprofile
if [ "$(( ls /etc/zsh/zprofile.d/*.zsh ) 2> /dev/null | wc --lines)" -gt '0' ]; then
	for f in /etc/zsh/zprofile.d/*.zsh; do
		. "$f"
	done
fi

EOF_
EOF

COPY files/etc/zsh/zprofile.d/01--profile.zsh /etc/zsh/zprofile.d/

RUN mkdir --parents /etc/zsh/zshrc.d
COPY files/etc/zsh/zshrc /tmp/
RUN <<EOF
echo >> /etc/zsh/zshrc
cat /tmp/zshrc >> /etc/zsh/zshrc
rm /tmp/zshrc
EOF

ENV ZNAP_HOME=/opt/zsh-snap
COPY files/opt/zsh-snap/ /opt/zsh-snap
RUN chmod --recursive g-w /opt/zsh-snap
COPY files/etc/zsh/zshrc.d/01--znap-repos.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc.d/02--znap.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc.d/03--znap-plugins.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc.d/50--bindkey.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc.d/50--history.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc.d/50--prompt.zsh /etc/zsh/zshrc.d/
COPY files/etc/zsh/zshrc.d/80--aliases.zsh /etc/zsh/zshrc.d/

RUN <<EOF
zsh <<EOI
. /etc/zsh/zshrc.d/01--znap-repos.zsh
. /etc/zsh/zshrc.d/02--znap.zsh

# For fast install, clone plugins in parallel.
# This is an optimization. It should be safe to remove this,
#  at the cost of speed.
znap clone \
	Aloxaf/fzf-tab \
	zsh-users/{zsh-autosuggestions,zsh-syntax-highlighting}
EOI
EOF

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

RUN mkdir /root/.zprofile.d
COPY files/root/.zprofile /root/

RUN <<-'EOF'
	su - ubuntu <<-'EOI'
		touch "$HOME/.zshrc"
	EOI
EOF

COPY --chmod=755 files/usr/sbin/for_all_users /usr/sbin/

RUN <<-'EOF'
	curl --silent --show-error --fail --location https://mise.jdx.dev/gpg-key.pub \
		| gpg --dearmor --output /etc/apt/keyrings/mise-archive-keyring.gpg -
	chmod 644 /etc/apt/keyrings/mise-archive-keyring.gpg
	mkdir --parents /etc/mise
EOF
COPY files/etc/apt/sources.list.d/mise.list /etc/apt/sources.list.d/mise.list
RUN /usr/sbin/install_clean --install-recommends mise
COPY files/etc/zsh/zprofile.d/50--mise.zsh /etc/zsh/zprofile.d/
COPY --chmod=755 files/usr/sbin/mise_use_system_tool /usr/sbin/
COPY --chmod=755 files/usr/sbin/mise_link_system_tools /usr/sbin/

RUN <<-'EOF' bash
	/usr/sbin/mise_use_system_tool python@3
	curl --silent --show-error --fail --location https://astral.sh/uv/install.sh \
		| env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh
EOF

ARG git_plus_version
RUN /usr/sbin/mise_use_system_tool pipx:git-plus@$git_plus_version

COPY files/opt/git-subrepo /opt/git-subrepo
COPY files/etc/zsh/zprofile.d/50--git-subrepo.zsh /etc/zsh/zprofile.d/
RUN \
	mkdir --parents /usr/local/share/man/man1; \
	ln --symbolic /opt/git-subrepo/man/man1/git-subrepo.1 /usr/local/share/man/man1/git-subrepo.1

ARG starship_version
RUN \
	mkdir --parents /tmp/starship_$starship_version; \
	curl --silent --show-error --location --fail \
		--output /tmp/starship_$starship_version/starship.tar.gz \
		https://github.com/starship/starship/releases/download/$starship_version/starship-x86_64-unknown-linux-gnu.tar.gz; \
	tar --extract --gzip --file=/tmp/starship_$starship_version/starship.tar.gz --directory=/tmp/starship_$starship_version; \
	cp /tmp/starship_$starship_version/starship /usr/local/bin/starship; \
	chmod 755 /usr/local/bin/starship; \
	rm --recursive --force /tmp/starship_$starship_version

COPY --chmod=755 files/sbin/entrypoint /sbin/
ENTRYPOINT ["/usr/bin/tini", "--", "/sbin/entrypoint"]
CMD ["/bin/zsh", "--login"]

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
RUN ln --symbolic /sbin/docker-entrypoint.sh /etc/entrypoint.d/49-docker.sh

FROM docker_cli AS docker

RUN rm /etc/entrypoint.d/49-docker.sh

# https://github.com/moby/moby/blob/0eecd59153c03ced5f5ddd79cc98f29e4d86daec/project/PACKAGERS.md#runtime-dependencies
# https://github.com/docker/docker-ce-packaging/blob/963aa02666035d4e268f33c63d7868d6cdd1d34c/deb/common/control#L28-L41
RUN /usr/sbin/install_clean \
	e2fsprogs \
	git \
	iproute2 \
	iptables \
	kmod \
	pigz \
	procps \
	uidmap \
	xfsprogs \
	xz-utils
RUN update-alternatives --set iptables /usr/sbin/iptables-nft

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN <<EOF
set -o errexit -o nounset
addgroup --system dockremap
adduser --system --ingroup dockremap dockremap
echo 'dockremap:165536:65536' >> /etc/subuid
echo 'dockremap:165536:65536' >> /etc/subgid
EOF

RUN /usr/sbin/install_clean \
	docker-ce \
	containerd.io

VOLUME /var/lib/docker
EXPOSE 2375 2376

COPY --chmod=644 files/sbin/dockerd-entrypoint.sh /sbin/
COPY --chmod=755 files/sbin/dockerd-entrypoint /sbin/
RUN ln --symbolic /sbin/dockerd-entrypoint.sh /etc/entrypoint.d/49-dockerd.sh
CMD []

FROM dev_base_image AS node

RUN <<-'EOF'
	/usr/sbin/mise_use_system_tool node@lts
	/usr/sbin/mise_use_system_tool npm:corepack@latest
	/usr/sbin/for_all_users /bin/bash <<-EOI
		eval "\$(mise activate bash --shims)"
		corepack enable pnpm
		corepack install --global pnpm@latest
	EOI
EOF

FROM docker_cli AS k8s

ARG k0s_version
RUN <<EOF
enc_ver=$(jq --raw-output --null-input --arg _ "$k0s_version" '$_ | @uri')
curl --silent --show-error --location --fail \
	--output /usr/local/bin/k0s \
	https://github.com/k0sproject/k0s/releases/download/$enc_ver/k0s-$enc_ver-amd64
chmod 755 /usr/local/bin/k0s
mkdir --parents /etc/k0s
/usr/local/bin/k0s config create > /etc/k0s/k0s.yaml
EOF
COPY --chmod=755 files/usr/local/bin/kubectl /usr/local
COPY --chmod=644 files/sbin/k0s.sh /sbin/
RUN ln --symbolic /sbin/k0s.sh /etc/entrypoint.d/48-k0s.sh

ARG k0sctl_version
RUN <<EOF
curl --silent --show-error --location --fail \
	--output /usr/local/bin/k0sctl \
	https://github.com/k0sproject/k0sctl/releases/download/$k0sctl_version/k0sctl-linux-amd64
chmod 755 /usr/local/bin/k0sctl
EOF

ARG skaffold_version
RUN <<EOF
curl --silent --show-error --location --fail \
	--output /usr/local/bin/skaffold \
	https://storage.googleapis.com/skaffold/releases/$skaffold_version/skaffold-linux-amd64
chmod 755 /usr/local/bin/skaffold
EOF

##region(collapsed) kustomize
ARG kustomize_version
RUN <<EOF
mkdir --parents /tmp/kustomize_$kustomize_version
curl --silent --show-error --location --fail \
	--output /tmp/kustomize_$kustomize_version/kustomize.tar.gz \
	https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F$kustomize_version/kustomize_${kustomize_version}_linux_amd64.tar.gz
tar --extract --gzip --file=/tmp/kustomize_$kustomize_version/kustomize.tar.gz --directory=/tmp/kustomize_$kustomize_version
cp /tmp/kustomize_$kustomize_version/kustomize /usr/local/bin/kustomize
chmod 755 /usr/local/bin/kustomize
rm --recursive --force /tmp/kustomize_$kustomize_version
EOF
##endregion

ARG k9s_version
RUN <<EOF
mkdir --parents /tmp/k9s_$k9s_version
curl --silent --show-error --location --fail \
	--output /tmp/k9s_$k9s_version/k9s.tar.gz \
	https://github.com/derailed/k9s/releases/download/$k9s_version/k9s_Linux_x86_64.tar.gz
tar --extract --gzip --file=/tmp/k9s_$k9s_version/k9s.tar.gz --directory=/tmp/k9s_$k9s_version
cp /tmp/k9s_$k9s_version/k9s /usr/local/bin/k9s
chmod 755 /usr/local/bin/k9s
rm --recursive --force /tmp/k9s_$k9s_version
EOF
