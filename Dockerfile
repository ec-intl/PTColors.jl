ARG JULIA_VERSION=1.11
FROM github/super-linter:v5 AS ci-linting
ARG WKDIR=/tmp/lint
WORKDIR "${WKDIR}"
RUN mkdir -p "${WKDIR}"
COPY . "${WKDIR}"

# The official Julia image uses Debian Bookworm Slim and supports AMD64 and ARM64.
FROM julia:${JULIA_VERSION}-bookworm AS noninteractive
ARG USERNAME
ARG USER_UID=1066
ARG USER_GID=${USER_UID}
ARG WKDIR=/ptcolors.jl
WORKDIR "${WKDIR}"

RUN mkdir -p /tmp "${WKDIR}" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo=1.9.13p3-1+deb12u4 && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" \
        --shell /bin/bash --create-home "${USERNAME}" && \
    echo "${USERNAME}" ALL=\(root\) NOPASSWD:ALL \
        > /etc/sudoers.d/"${USERNAME}" && \
    chmod 0440 /etc/sudoers.d/"${USERNAME}" && \
    chown -R "${USERNAME}" /tmp "${WKDIR}"

FROM noninteractive AS interactive
RUN mkdir -p \
        /root/.vscode-server/extensions \
        /root/.vscode-server-insiders/extensions \
        /root/.vscode-remote/extensions \
        /root/.vscode-remote-insiders/extensions \
        /root/.vscode-server/bin \
        /root/.vscode-server-insiders/bin \
        /root/.vscode-remote/bin \
        /root/.vscode-remote-insiders/bin && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bsdextrautils=2.38.1-5+deb12u3 \
        git=1:2.39.5-0+deb12u3 \
        openssh-client=1:9.2p1-2+deb12u10 \
        unzip=6.0-28 && \
    rm -rf /var/lib/apt/lists/*

FROM noninteractive AS transfer
COPY . "${WKDIR}"
RUN chown -R "${USERNAME}":"${USERNAME}" "${WKDIR}"
USER "${USERNAME}"

FROM transfer AS production

FROM transfer AS staging

FROM transfer AS ci-testing

FROM noninteractive AS testing
USER "${USERNAME}"

FROM interactive AS developing
COPY ./.devcontainer/install.sh /tmp/install
COPY ./.devcontainer/bash-src/ /tmp/bash-src/
COPY ./scripts/dev/.sleeping_daemon.sh /tmp/
USER "${USERNAME}"
