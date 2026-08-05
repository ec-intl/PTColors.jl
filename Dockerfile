FROM github/super-linter:v5 AS ci-linting
ARG WKDIR=/tmp/lint
WORKDIR "${WKDIR}"
RUN mkdir -p "${WKDIR}"
COPY . "${WKDIR}"

FROM ubuntu:24.04 AS noninteractive
ARG USERNAME
ARG USER_UID=1066
ARG USER_GID=$USER_UID
ARG WKDIR=/template-repository
WORKDIR ${WKDIR}
RUN mkdir -p /tmp "${WKDIR}" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bash=5.2.21-2ubuntu4 \
        sudo=1.9.15p5-3ubuntu5 && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell /bin/bash --create-home "${USERNAME}" && \
    echo "${USERNAME}" ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/"${USERNAME}" && \
    chmod 0440 /etc/sudoers.d/"${USERNAME}" && \
    chown -R "${USERNAME}" /tmp && \
    chown -R "${USERNAME}" "${WKDIR}"

FROM noninteractive AS interactive
RUN mkdir -p /root/.vscode-server/extensions \
        /root/.vscode-server-insiders/extensions \
        /root/.vscode-remote/extensions \
        /root/.vscode-remote-insiders/extensions \
        /root/.vscode-server/bin \
        /root/.vscode-server-insiders/bin \
        /root/.vscode-remote/bin \
        /root/.vscode-remote-insiders/bin && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bsdextrautils=2.39.3-9ubuntu6.5 \
        curl=8.5.0-2ubuntu10.8 \
        git=1:2.43.0-1ubuntu7.3 \
        openssh-client=1:9.6p1-3ubuntu13.15 \
        unzip=6.0-28ubuntu4.1 \
        software-properties-common=0.99.49.4 && \
    rm -rf /var/lib/apt/lists/*

FROM noninteractive AS transfer
COPY . ${WKDIR}
RUN chown -R "${USERNAME}":"${USERNAME}" "${WKDIR}"
USER ${USERNAME}
FROM transfer AS production
FROM transfer AS staging
FROM transfer AS ci-testing
FROM noninteractive AS testing
USER ${USERNAME}
FROM interactive AS developing
COPY ./.devcontainer/install.sh /tmp/install
COPY ./.devcontainer/bash-src/ /tmp/bash-src/
COPY ./scripts/dev/.sleeping_daemon.sh /tmp/
USER ${USERNAME}
