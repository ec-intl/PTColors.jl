FROM github/super-linter:v5 AS ci-linting
ARG WKDIR=/tmp/lint
WORKDIR "${WKDIR}"
RUN mkdir -p "${WKDIR}"
COPY . "${WKDIR}"

FROM ubuntu:24.04 AS noninteractive
ARG USERNAME
ARG USER_UID=1066
ARG USER_GID=${USER_UID}
ARG WKDIR=/ptcolors.jl
WORKDIR "${WKDIR}"
RUN mkdir -p /tmp "${WKDIR}" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bash=5.2.21-2ubuntu4 \
        ca-certificates=20260601~24.04.1 \
        sudo=1.9.15p5-3ubuntu5.24.04.2 \
        tar=1.35+dfsg-3ubuntu0.4 \
        wget=1.21.4-1ubuntu4.4 && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" \
        --shell /bin/bash --create-home "${USERNAME}" && \
    echo "${USERNAME}" ALL=\(root\) NOPASSWD:ALL \
        > /etc/sudoers.d/"${USERNAME}" && \
    chmod 0440 /etc/sudoers.d/"${USERNAME}" && \
    chown -R "${USERNAME}" /tmp "${WKDIR}"

# Install Julia 1.11.0 for the current container architecture.
ARG TARGETARCH
ARG JULIA_VERSION=1.11.0
RUN set -eux; \
    arch="${TARGETARCH:-}"; \
    if [ -z "${arch}" ]; then \
        arch="$(dpkg --print-architecture)"; \
    fi; \
    case "${arch}" in \
        amd64) \
            JULIA_ARCH="x86_64"; \
            JULIA_PATH="x64"; \
            JULIA_SHA256="bcf815553fda2ed7910524c8caa189c8e8191a40a799dd8b5fbed0d9dd6b882c" \
            ;; \
        arm64) \
            JULIA_ARCH="aarch64"; \
            JULIA_PATH="aarch64"; \
            JULIA_SHA256="66b9195b4c6b85403834dca9ef4fcae75f15be906bb3bb2c48eccb780ab810a1" \
            ;; \
        *) \
            echo "Unsupported architecture: ${arch}"; \
            exit 1 \
            ;; \
    esac; \
    JULIA_TARBALL="julia-${JULIA_VERSION}-linux-${JULIA_ARCH}.tar.gz"; \
    wget --progress=dot:giga \
        "https://julialang-s3.julialang.org/bin/linux/${JULIA_PATH}/1.11/${JULIA_TARBALL}"; \
    echo "${JULIA_SHA256}  ${JULIA_TARBALL}" | sha256sum --check; \
    tar -xzf "${JULIA_TARBALL}"; \
    rm "${JULIA_TARBALL}"; \
    mv "julia-${JULIA_VERSION}" "/opt/julia-${JULIA_VERSION}"; \
    ln -s "/opt/julia-${JULIA_VERSION}/bin/julia" /usr/local/bin/julia


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
        bsdextrautils=2.39.3-9ubuntu6.5 \
        curl=8.5.0-2ubuntu10.11 \
        git=1:2.43.0-1ubuntu7.3 \
        openssh-client=1:9.6p1-3ubuntu13.18 \
        software-properties-common=0.99.49.4 \
        unzip=6.0-28ubuntu4.1 && \
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
