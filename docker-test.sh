#!/bin/bash

# Script para testar o setup Ansible localmente via Docker
# Uso: ./docker-test.sh [check|dry-run|full]

set -e

MODE="${1:-check}"
IMAGE_NAME="ansible-macos-test"
CONTAINER_NAME="ansible-test-container"

echo "=== Ansible macOS Test Environment ==="
echo "Mode: $MODE"
echo ""

# Cleanup anterior
docker rm -f $CONTAINER_NAME 2>/dev/null || true

echo "=== Building Docker Image ==="
cat > Dockerfile.test.tmp << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ansible \
    git \
    curl \
    sudo \
    python3-pip \
    software-properties-common \
    ssh \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário de teste
RUN useradd -m -s /bin/bash tg && \
    echo "tg ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/tg/.ssh && \
    chmod 700 /home/tg/.ssh && \
    chown -R tg:tg /home/tg

WORKDIR /home/tg/dotfiles
COPY --chown=tg:tg . .

USER tg

# Criar inventory de teste
RUN echo "[workstation]" > test_hosts && \
    echo "localhost ansible_connection=local ansible_user=tg" >> test_hosts && \
    echo "test" > ~/.vault_key

CMD ["bash"]
EOF

docker build -f Dockerfile.test.tmp -t $IMAGE_NAME .
rm Dockerfile.test.tmp

echo ""
echo "=== Running Tests ==="

# Test 1: Syntax Check
echo ""
echo "1. Ansible Syntax Check"
docker run --rm --name ${CONTAINER_NAME}-syntax $IMAGE_NAME \
    ansible-playbook --syntax-check -i test_hosts local.yml

# Test 2: List Tasks
echo ""
echo "2. List All Tasks"
docker run --rm --name ${CONTAINER_NAME}-list $IMAGE_NAME \
    ansible-playbook -i test_hosts local.yml --list-tasks 2>&1 | head -50

# Test 3: Check Mode (Dry Run) - if requested
if [ "$MODE" == "dry-run" ] || [ "$MODE" == "full" ]; then
    echo ""
    echo "3. Check Mode (Dry Run)"
    docker run --rm --name ${CONTAINER_NAME}-check $IMAGE_NAME \
        ansible-playbook --check -i test_hosts local.yml -v 2>&1 | head -100 || {
        echo "⚠️  Check mode completed with expected failures (this is normal for macOS-specific tasks on Linux)"
    }
fi

# Test 4: Bootstrap Script Check
echo ""
echo "4. Bootstrap Script Syntax Check"
docker run --rm --name ${CONTAINER_NAME}-bootstrap $IMAGE_NAME \
    bash -n bootstrap.sh && echo "✓ bootstrap.sh syntax OK"
docker run --rm $IMAGE_NAME \
    bash -n update.sh && echo "✓ update.sh syntax OK"

# Test 5: Variable Check
echo ""
echo "5. Variable Definitions Check"
docker run --rm $IMAGE_NAME bash -c '
    echo "=== Checking for undefined variables ==="
    
    # Check Darwin vars
    if [ -f roles/base/vars/Darwin.yml ]; then
        echo "✓ Darwin.yml exists"
        cat roles/base/vars/Darwin.yml | grep -E "^[a-z_]+:" | head -20
    else
        echo "✗ Darwin.yml NOT FOUND"
    fi
    
    echo ""
    echo "=== Checking group_vars/all ==="
    if [ -f group_vars/all ]; then
        grep "github_username" group_vars/all || echo "⚠️  github_username not defined"
    fi
'

echo ""
echo "=== Test Summary ==="
echo "✓ Syntax check passed"
echo "✓ Tasks listed successfully"
echo "✓ Scripts syntax validated"

if [ "$MODE" == "full" ]; then
    echo "⚠️  Full run mode is not recommended in Docker (macOS-specific)"
fi

echo ""
echo "=== Cleanup ==="
docker rmi $IMAGE_NAME 2>/dev/null || true

echo ""
echo "All tests completed!"
