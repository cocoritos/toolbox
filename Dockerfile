FROM node:21.6.1-bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive \
    ARCH=arm64 \
    ANSIBLE_VERSION=9.2.0 \
    ARGOCD_VERSION=2.9.6 \
    HELM_VERSION=3.14.0 \
    HVAC_VERSION=2.1.0 \
    J2CLI_VERSION=0.3.10 \
    KUBECTL_VERSION=1.29.1 \
    TERRAFORM_VERSION=1.7.2 \
    YQ_VERSION=4.40.5

ENV PATH="/opt/venv/bin:$PATH"

# Install base packages
RUN set -ex; \
    apt update && apt upgrade -y; \
    apt install -y \
        bash-completion \
        curl \
        default-mysql-client \
        dnsutils \
        git \
        jq \
        procps \
        pv \
        python3 \
        python3-distutils \
        python3-venv \
        sudo \
        unzip \
        virtualenv \
        wget; \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*;

# Install services
RUN set -ex; \
    # set ARCH dynamically
    case "$(uname -m)" in \
        aarch64) ARCH=arm64 ;; \
        x86_64) ARCH=amd64 ;; \
        *) echo "Unsupported architecture"; exit 1 ;; \
    esac; \
    echo "Building for architecture: $ARCH"; \
    # python virtual env
    python3 -m venv /opt/venv; \
    # python
    curl -sL https://bootstrap.pypa.io/get-pip.py | python3; \
    ln -sf /usr/bin/python3 /usr/bin/python; \
    # ansible
    python -m pip install ansible==${ANSIBLE_VERSION}; \
    # hvac
    python -m pip install hvac==${HVAC_VERSION}; \
    # j2
    python -m pip install j2cli==${J2CLI_VERSION}; \
    # argocd
    wget -q https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${ARCH} -P /tmp/; \
    chmod +x /tmp/argocd-linux-${ARCH}; \
    mv /tmp/argocd-linux-${ARCH} /usr/local/bin/argocd; \
    # helm
    wget -q https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz -P /tmp/; \
    tar -zxf /tmp/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz -C /tmp/; \
    chmod +x /tmp/linux-${ARCH}/helm; \
    mv /tmp/linux-${ARCH}/helm /usr/local/bin/helm; \
    # kubectl
    wget -q https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl -P /tmp/; \
    chmod +x /tmp/kubectl; \
    mv /tmp/kubectl /usr/local/bin/kubectl; \
    kubectl completion bash > /etc/bash_completion.d/kubectl; \
    # terraform
    wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip -P /tmp/; \
    unzip /tmp/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip -d /usr/local/bin/; \
    # yq
    wget -q https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH} -P /tmp/; \
    chmod +x /tmp/yq_linux_${ARCH}; \
    mv /tmp/yq_linux_${ARCH} /usr/local/bin/yq; \
    # cleaning
    rm -rf /tmp/*;
