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
