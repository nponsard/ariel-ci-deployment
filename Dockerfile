FROM docker.io/rust:1-slim-trixie

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG RUNNER_VERSION=2.327.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.7.0
ARG RUNNER_ARCH=x64
ARG RUST_NIGHTLY_TOOLCHAIN=nightly-2025-02-25
ARG RUST_STABLE_TOOLCHAIN=1.89.0
ARG RUST_XTENSA_TOOLCHAIN_VERSION=1.85.0.0
ARG RUST_XTENSA_TARGETS=esp32s3
ARG RUST_TARGETS=riscv32imc-unknown-none-elf,riscv32imac-unknown-none-elf,thumbv6m-none-eabi,thumbv7m-none-eabi,thumbv7em-none-eabi,thumbv7em-none-eabihf,thumbv8m.main-none-eabi,thumbv8m.main-none-eabihf
ARG RUST_COMPONENTS=rust-src,rustfmt
ARG LAZE_VERSION=^0.1
ARG ESPUP_VERSION=0.15.1
ARG SCCACHE_VERSION=0.10.0

ENV UID=1000
ENV GID=0
ENV USERNAME="runner"

# dotnet icu error workaround, for the runner https://stackoverflow.com/questions/72536918/net6-and-docker-couldnt-find-a-valid-icu-package-installed-on-the-system 
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update \
  # Tool dependencies
  && apt-get install -y --no-install-recommends curl sudo ca-certificates unzip libssl-dev\
  # Ariel dependencies
  && apt-get install -y git ninja-build pkg-config libudev-dev clang gcc-arm-none-eabi gcc-riscv64-unknown-elf gcc curl build-essential \
  && apt-get dist-clean

# Runner user
RUN useradd --uid ${UID} runner -G 0 \
  && usermod -aG sudo runner \
  && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

RUN mkdir -p /home/${USERNAME} \
  && chown -R $USERNAME:$GID /home/${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME /home/${USERNAME}

USER runner

# Runner download supports amd64 as x64
RUN curl -L -o runner.tar.gz https://github.com/falcondev-oss/github-actions-runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
  && tar xzf ./runner.tar.gz \
  && rm runner.tar.gz \
  && sudo ./bin/installdependencies.sh \
  && sudo apt-get dist-clean

# Install container hooks
RUN curl -f -L -o runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
  && unzip ./runner-container-hooks.zip -d ./k8s \
  && rm runner-container-hooks.zip

# Install nightly toolchain
RUN rustup toolchain install ${RUST_NIGHTLY_TOOLCHAIN} -c ${RUST_COMPONENTS}  -t ${RUST_TARGETS}
# Install stable
RUN rustup toolchain install ${RUST_STABLE_TOOLCHAIN} -c ${RUST_COMPONENTS} -t ${RUST_TARGETS}

# Install laze & espup
RUN cargo install laze@${LAZE_VERSION} --locked \
  && cargo install espup@${ESPUP_VERSION} --locked \
  && cargo install sccache@${SCCACHE_VERSION} --locked \
  # && rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/target \ 
  && rm -rf $CARGO_HOME/registry $CARGO_HOME/git $CARGO_HOME/target

# Install xtensa toolchain
RUN espup install -v ${RUST_XTENSA_TOOLCHAIN_VERSION} --targets ${RUST_XTENSA_TARGETS}
