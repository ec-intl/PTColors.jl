FROM github/super-linter:v5 AS ci-linting
ARG WKDIR=/tmp/lint
WORKDIR "${WKDIR}"
RUN mkdir -p "${WKDIR}"
COPY . "${WKDIR}"
FROM ubuntu:23.10 AS noninteractive
ARG USERNAME
ARG USER_UID=1066
ARG USER_GID=$USER_UID
ARG WKDIR=/template-repository
WORKDIR ${WKDIR}
RUN mkdir -p /tmp "${WKDIR}" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bash=5.2.15-2ubuntu1 \
        sudo=1.9.14p2-1ubuntu1 && \
    rm -rf /var/lib/apt/lists/./* && \
    groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_GID}" --gid "${USER_GID}" --shell /bin/bash --create-home "${USERNAME}" && \
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
        bsdextrautils=2.39.1-4ubuntu2.2 \
        curl=8.2.1-1ubuntu3.3 \
        git=1:2.40.1-1ubuntu1.1 \
        openssh-client=1:9.3p1-1ubuntu3.2 \
        unzip=6.0-28ubuntu1 \
        software-properties-common=0.99.39 && \
    rm -rf /var/lib/apt/lists/./*
FROM noninteractive as transfer
COPY . ${WKDIR}
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
