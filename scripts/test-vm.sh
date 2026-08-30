#!/usr/bin/env bash
set -euo pipefail

# test-vm.sh — testa o neonet numa VM macOS descartável (Tart, Apple Silicon).
#
# Por padrão testa a ÁRVORE LOCAL (rsync deste checkout para a VM e roda
# ansible-playbook lá dentro) — ou seja, valida ANTES do push.
#
# Uso:
#   scripts/test-vm.sh                 # testa working tree local, apaga a VM no fim
#   scripts/test-vm.sh --keep          # mantém a VM para inspeção (tart run neonet-test)
#   scripts/test-vm.sh --gui           # abre a janela da VM (útil p/ Gatekeeper/GUI)
#   scripts/test-vm.sh --from-github   # testa o bootstrap real (curl | bash do master)
#
# Env:
#   TART_HOME    onde ficam imagens/VMs (padrão Tart: ~/.tart). O disco interno
#                tem pouco espaço — use o volume externo: TART_HOME=/Volumes/life/tart
#   BASE_IMAGE   imagem base (padrão: ghcr.io/cirruslabs/macos-tahoe-base:latest)
#   VM_NAME      nome da VM de teste (padrão: neonet-test)

BASE_IMAGE="${BASE_IMAGE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
VM_NAME="${VM_NAME:-neonet-test}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MIN_FREE_GB=60

KEEP=0 GUI=0 FROM_GITHUB=0
for arg in "$@"; do
  case "$arg" in
    --keep) KEEP=1 ;;
    --gui) GUI=1 ;;
    --from-github) FROM_GITHUB=1 ;;
    *) echo "arg desconhecido: $arg" >&2; exit 2 ;;
  esac
done

die() { echo "ERRO: $*" >&2; exit 1; }

command -v tart >/dev/null || die "tart não instalado. Rode: brew install cirruslabs/cli/tart"
command -v sshpass >/dev/null || die "sshpass não instalado. Rode: brew install sshpass"

# Espaço em disco no destino das imagens
TART_DIR="${TART_HOME:-$HOME/.tart}"
mkdir -p "$TART_DIR"
free_gb=$(df -g "$TART_DIR" | awk 'NR==2 {print $4}')
if [ "$free_gb" -lt "$MIN_FREE_GB" ] && ! tart list 2>/dev/null | grep -q "$(basename "$BASE_IMAGE" | cut -d: -f1)"; then
  die "só ${free_gb}GB livres em $TART_DIR (mínimo ${MIN_FREE_GB}GB p/ baixar a imagem base).
Monte o volume externo e use: TART_HOME=/Volumes/life/tart $0 $*"
fi

echo "==> Imagem base: $BASE_IMAGE (TART_HOME=$TART_DIR)"
tart pull "$BASE_IMAGE"

tart delete "$VM_NAME" 2>/dev/null || true
tart clone "$BASE_IMAGE" "$VM_NAME"

echo "==> Iniciando VM $VM_NAME"
if [ "$GUI" -eq 1 ]; then
  tart run "$VM_NAME" &
else
  tart run --no-graphics "$VM_NAME" &
fi
VM_PID=$!

cleanup() {
  if [ "$KEEP" -eq 0 ]; then
    echo "==> Apagando VM $VM_NAME"
    kill "$VM_PID" 2>/dev/null || true
    wait "$VM_PID" 2>/dev/null || true
    tart delete "$VM_NAME" 2>/dev/null || true
  else
    echo "==> VM mantida. Acesse com: ssh admin@$(tart ip "$VM_NAME" 2>/dev/null || echo '<tart ip '"$VM_NAME"'>') (senha: admin)"
  fi
}
trap cleanup EXIT

echo "==> Aguardando IP da VM..."
IP=""
for _ in $(seq 1 60); do
  IP=$(tart ip "$VM_NAME" 2>/dev/null) && [ -n "$IP" ] && break
  sleep 2
done
[ -n "$IP" ] || die "VM não obteve IP em 120s"

SSH=(sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "admin@$IP")
echo "==> VM pronta em $IP; aguardando SSH..."
for _ in $(seq 1 30); do
  "${SSH[@]}" true 2>/dev/null && break
  sleep 2
done

START=$(date +%s)
if [ "$FROM_GITHUB" -eq 1 ]; then
  echo "==> Rodando bootstrap real (GitHub master) dentro da VM"
  RC=0
  "${SSH[@]}" 'curl -Lks https://raw.githubusercontent.com/homeofficehost/neonet/master/bootstrap.sh | /bin/bash' || RC=$?
else
  echo "==> Copiando working tree local para a VM"
  sshpass -p admin rsync -az --delete \
    --exclude .git --exclude cache --exclude .ansible_async \
    -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "$REPO_DIR/" "admin@$IP:~/neonet/"
  echo "==> Instalando ansible e aplicando playbook LOCAL dentro da VM"
  RC=0
  "${SSH[@]}" 'command -v brew >/dev/null || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
command -v ansible-playbook >/dev/null || brew install ansible
cd ~/neonet && ansible-playbook -i "localhost," -c local local.yml' || RC=$?
fi
ELAPSED=$(( $(date +%s) - START ))

echo
if [ "$RC" -eq 0 ]; then
  echo "✅ Provisioning OK na VM em ${ELAPSED}s"
else
  echo "❌ Provisioning falhou (rc=$RC) após ${ELAPSED}s — VM mantida? use --keep para inspecionar"
fi
exit "$RC"
