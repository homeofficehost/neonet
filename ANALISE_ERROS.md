# Análise Completa do Projeto Ansible - Erros e Soluções

## 📋 RESUMO DA ANÁLISE

**Status Geral:** ✅ Estrutura funcional, mas com vários pontos de atenção
**Complexidade:** Alta (múltiplos pontos de falha potenciais)
**Risco:** Médio-Alto (produção sem testes adequados)

---

## 🚨 ERROS CRÍTICOS ENCONTRADOS

### 1. **Variáveis Não Definidas (CRÍTICO)**

**Arquivo:** `roles/base/tasks/ansible_setup.yml` (linhas 11-12)
```yaml
- name: ansible setup | install required packages
  package:
    name:
      - "{{ dconf_package }}"      # ❌ Não definido no Darwin.yml
      - "{{ python_psutil_package }}"  # ❌ Não definido no Darwin.yml
```

**Problema:** Essas variáveis são Linux-only e não existem em `vars/Darwin.yml`
**Impacto:** Falha no playbook ao tentar instalar pacotes
**Solução:** 
```yaml
# Adicionar em roles/base/vars/Darwin.yml:
dconf_package: ""  # N/A on macOS
python_psutil_package: python-psutil  # Ou deixar vazio e adicionar condição when

# OU adicionar condição na task:
when: ansible_distribution != "Darwin"
```

---

### 2. **Referência a Usuário Inexistente (CRÍTICO)**

**Arquivo:** `roles/base/tasks/system_setup/cron.yml` (linhas 14, 32)
```yaml
user: velociraptor
```

**Arquivo:** `roles/base/tasks/ansible_setup.yml` (linha 25)
```yaml
owner: velociraptor
```

**Problema:** O usuário `velociraptor` foi removido nas limpezas, mas ainda é referenciado
**Impacto:** Falha ao criar cron jobs e definir permissões
**Solução:** Substituir por `{{ username }}` ou `{{ ansible_user }}`

---

### 3. **Referência a Arquivos Inexistentes (CRÍTICO)**

**Arquivo:** `roles/base/tasks/ansible_setup.yml` (linhas 31-38)
```yaml
- name: ansible setup | add logrotate config
  copy:
    src: files/ansible_setup/logrotate  # ❌ Diretório foi deletado
    dest: /etc/logrotate.d/ansible
```

**Problema:** O diretório `files/ansible_setup/` foi removido na limpeza
**Impacto:** Falha na task de copy
**Solução:** 
- Recriar o arquivo template em `roles/base/files/ansible_setup/logrotate`
- Ou remover a task se não for necessária no macOS

---

### 4. **Path Incorreto no Bootstrap (ALTO)**

**Arquivo:** `bootstrap.sh` (linha 84)
```bash
ansible-pull --vault-password-file ~/.vault_key --url https://github.com/homeofficehost/dotfiles --limit "$(hostname -s).local" --checkout master
```

**Problema:** 
- O arquivo `.vault_key` pode não existir
- O limit usa `$(hostname -s).local` mas o hosts file tem `tgworkmac.local`
- Se o hostname não for `tgworkstation`, o limit não matcha

**Impacto:** Ansible não encontra o host ou falha no vault
**Solução:**
```bash
# Verificar se vault_key existe
if [ -f ~/.vault_key ]; then
  ansible-pull --vault-password-file ~/.vault_key ...
else
  echo "Warning: ~/.vault_key not found, running without vault"
  ansible-pull --url https://github.com/homeofficehost/dotfiles --limit "$(hostname -s).local" --checkout master
fi
```

---

### 5. **Lógica Invertida no Bootstrap (MÉDIO)**

**Arquivo:** `bootstrap.sh` (linhas 13-20)
```bash
if [ ! -f ~/.ssh/tgroch_id_rsa ]; then
  chown $LOCAL_USER:$LOCAL_USER ~/.ssh/tgroch_id_rsa  # ❌ Arquivo não existe!
  # ...
fi
```

**Problema:** Se o arquivo NÃO existe, tenta fazer chown nele
**Impacto:** Erro "No such file or directory"
**Solução:**
```bash
# Criar diretório .ssh se não existir
if [ ! -d ~/.ssh ]; then
  mkdir -p ~/.ssh
  chown $LOCAL_USER:$LOCAL_USER ~/.ssh
  chmod 700 ~/.ssh
fi

# Só fazer chown se o arquivo existir
if [ -f ~/.ssh/tgroch_id_rsa ]; then
  chown $LOCAL_USER:$LOCAL_USER ~/.ssh/tgroch_id_rsa
  chmod 600 ~/.ssh/tgroch_id_rsa
fi
```

---

### 6. **Referência a Playbooks Movidos (CRÍTICO)**

**Arquivo:** `local.yml` (linhas 16, 21)
```yaml
include_tasks: playbooks/send_completion_alert.yml
include_tasks: playbooks/send_failure_alert.yml
```

**Problema:** Os playbooks foram movidos para `linux/playbooks/`
**Impacto:** Ansible não encontra os arquivos
**Solução:** 
```yaml
include_tasks: linux/playbooks/send_completion_alert.yml
include_tasks: linux/playbooks/send_failure_alert.yml
```

Ou mover de volta para `playbooks/` na raiz

---

### 7. **Condição Incompleta no Hosts (MÉDIO)**

**Arquivo:** `hosts`
```ini
[base]

[workstation]
tgworkmac.local ansible_sudo=True
```

**Problema:** O grupo `[base]` está vazio, mas o playbook `local.yml` usa `hosts: localhost`
**Impacto:** O inventory não é usado corretamente
**Solução:**
```ini
[workstation]
tgworkmac.local ansible_sudo=True ansible_user=tg

[workstation:vars]
ansible_connection=local
```

E atualizar o `local.yml`:
```yaml
- hosts: workstation
```

---

### 8. **Tasks Workstation Referenciam Arquivos Movidos (MÉDIO)**

**Arquivo:** `roles/workstation/tasks/main.yml` (linhas 11-19)
```yaml
- include_tasks: desktop_environments/mate/main.yml
- include_tasks: desktop_environments/gnome/main.yml
```

**Problema:** Esses arquivos foram movidos para `linux/roles/workstation/tasks/desktop_environments/`
**Impacto:** Tasks não encontradas (mas têm `when: ansible_distribution != "Darwin"`, então não executam no Mac)
**Solução:** Atualizar o path ou remover as tasks se não forem usar no Mac

---

### 9. **Token do Telegram em Plain Text (BAIXO - SEGURANÇA)**

**Arquivo:** `group_vars/all` (linha 14)
```yaml
telegram_token: "6920636205:AAEVlLX5JTJY9NjMuRg1-5KDySdzgPBPJS0"
```

**Problema:** Token exposto no repositório
**Impacto:** Segurança comprometida
**Solução:** Mover para Ansible Vault

---

### 10. **Falta de Validação de Erros (MÉDIO)**

**Arquivo:** `bootstrap.sh` (linhas 28-30)
```bash
if [[ $(uname) == "Darwin" ]] && ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
```

**Problema:** Não verifica se a instalação do brew foi bem-sucedida
**Impacto:** Continua execução mesmo se brew falhar
**Solução:**
```bash
if [[ $(uname) == "Darwin" ]] && ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "Failed to install Homebrew"
    exit 1
  }
  # Adicionar ao PATH se necessário
  eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
  # eval "$(/usr/local/bin/brew shellenv)"   # Intel
fi
```

---

## ⚠️ PROBLEMAS DE ARQUITETURA

### 11. **Acoplamento Forte com Linux**

**Problema:** Muitas tasks têm `when: ansible_distribution != "Darwin"`, o que significa que o playbook tenta executar tudo e depois pula
**Impacto:** Performance, legibilidade, manutenção
**Solução:** Separar em roles específicas:
- `roles/base-macos/`
- `roles/base-linux/`
- `roles/common/` (código compartilhado)

### 12. **Mistura de Configuração e Instalação**

**Problema:** O mesmo playbook faz:
- Instalação de pacotes do sistema
- Configuração de dotfiles
- Setup de cron
- Download de chaves SSH

**Impacto:** Difícil debugar, não é idempotente em partes
**Solução:** Separar em playbooks específicos:
- `install.yml` - instalação inicial
- `configure.yml` - configuração de dotfiles
- `update.yml` - atualizações

### 13. **Dependência de Arquivos Externos**

**Problema:** 
- `.vault_key` precisa existir
- Chaves SSH precisam estar no GitHub
- Repositórios git precisam estar acessíveis

**Impacto:** Falha se qualquer dependência não estiver disponível
**Solução:** Documentar todas as dependências e criar verificações

---

## 🔧 SOLUÇÃO DE TESTE COM DOCKER

Como você está em Linux e o target é macOS, podemos criar um ambiente de teste usando Docker com um container que simule comportamentos macOS ou usar uma VM real.

### Opção 1: Docker com Ansible Check Mode (Recomendada)

**Arquivo:** `Dockerfile.test`
```dockerfile
FROM ubuntu:22.04

# Instalar dependências
RUN apt-get update && apt-get install -y \
    ansible \
    git \
    curl \
    sudo \
    python3-pip \
    software-properties-common

# Criar usuário de teste
RUN useradd -m -s /bin/bash tg && \
    echo "tg ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copiar o projeto
COPY . /home/tg/dotfiles
RUN chown -R tg:tg /home/tg/dotfiles

# Configurar Ansible para modo local
WORKDIR /home/tg/dotfiles
USER tg

# Criar inventory de teste
RUN echo "[workstation]" > test_hosts && \
    echo "localhost ansible_connection=local ansible_user=tg" >> test_hosts

# Entrypoint para testes
CMD ["bash"]
```

**Arquivo:** `docker-test.sh`
```bash
#!/bin/bash

# Build da imagem
docker build -f Dockerfile.test -t ansible-macos-test .

# Run syntax check
echo "=== Ansible Syntax Check ==="
docker run --rm ansible-macos-test ansible-playbook --syntax-check -i test_hosts local.yml || exit 1

# Run check mode (dry-run)
echo "=== Ansible Check Mode ==="
docker run --rm ansible-macos-test ansible-playbook --check -i test_hosts local.yml -v

# Run specific role test
echo "=== Test Base Role ==="
docker run --rm ansible-macos-test ansible-playbook --check -i test_hosts local.yml --tags base -v

echo "=== Tests Complete ==="
```

**Limitações:** Não testa:
- Comandos específicos do macOS (brew, mas)
- Paths do macOS (/Users/ vs /home/)
- Serviços do macOS (launchd vs systemd)

---

### Opção 2: VM macOS com Vagrant (Mais Realista)

**Arquivo:** `Vagrantfile`
```ruby
Vagrant.configure("2") do |config|
  # Usar uma box macOS (requer licença Apple)
  # Opções: "jhcook/macos-sierra" ou "ramsey/macos-catalina"
  config.vm.box = "jhcook/macos-sierra"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end
  
  # Compartilhar o projeto
  config.vm.synced_folder ".", "/Users/vagrant/dotfiles"
  
  # Provision com Ansible
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "local.yml"
    ansible.inventory_path = "hosts"
    ansible.limit = "workstation"
    ansible.verbose = "v"
  end
end
```

**Comandos:**
```bash
vagrant up
vagrant provision  # Re-executar ansible
vagrant ssh        # Entrar na VM para verificar
```

**Limitações:** 
- Requer licença macOS
- Não é legalmente permitido rodar macOS em não-Apple hardware (violEULA)
- Performance baixa em VirtualBox

---

### Opção 3: MacStadium / AWS Mac Instances (Produção)

Para testes reais em hardware Apple:

**AWS:**
```bash
# Lançar instância macOS na AWS (cara! ~$1-2/hora)
aws ec2 run-instances \
  --instance-type mac1.metal \
  --image-id ami-xxxxx \
  --key-name my-key
```

**MacStadium (especializado em CI/CD macOS):**
- Orquestração de Macs reais via API
- Integração com GitHub Actions
- Preço: ~$99-300/mês

---

### Opção 4: GitHub Actions com Runner macOS (Recomendada para CI)

**Arquivo:** `.github/workflows/test-macos.yml`
```yaml
name: Test macOS Setup

on:
  push:
    branches: [ master, main ]
  pull_request:
    branches: [ master, main ]

jobs:
  test-macos:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Ansible
      run: |
        brew install ansible
    
    - name: Create test vault key
      run: echo "test" > ~/.vault_key
    
    - name: Syntax Check
      run: |
        ansible-playbook --syntax-check -i hosts local.yml
    
    - name: Check Mode (Dry Run)
      run: |
        ansible-playbook --check -i hosts local.yml -v || true
      # '|| true' porque vai falhar em partes que esperam configuração
    
    - name: Test Bootstrap Script
      run: |
        bash -n bootstrap.sh
    
    - name: Test Brewfile
      run: |
        brew bundle check --file=Brewfile || true
```

**Vantagens:**
- ✅ Gratuito para repositórios públicos
- ✅ Hardware macOS real
- ✅ Integrado ao GitHub
- ✅ Roda a cada push/PR

**Limitações:**
- Timeout de 6 horas
- Não persiste entre runs
- Limitações de recursos

---

## 🎯 RECOMENDAÇÕES FINAIS

### Prioridade 1 - Corrigir Antes de Executar:
1. ✅ Corrigir referências a `velociraptor` → usar `{{ username }}`
2. ✅ Corrigir paths dos playbooks (`linux/playbooks/`)
3. ✅ Adicionar variáveis faltantes em `Darwin.yml`
4. ✅ Corrigir lógica do bootstrap.sh (chown)
5. ✅ Recriar arquivo `files/ansible_setup/logrotate` ou remover task

### Prioridade 2 - Melhorias:
6. Separar roles macOS/Linux para melhor manutenção
7. Criar playbook de teste específico
8. Implementar GitHub Actions para CI
9. Documentar dependências (`.vault_key`, chaves SSH, etc.)

### Prioridade 3 - Testes:
10. Configurar GitHub Actions (Opção 4)
11. Criar ambiente Docker para testes rápidos (Opção 1)
12. Considerar MacStadium para testes completos antes de produção

---

## 📊 CHECKLIST DE CORREÇÃO

```markdown
- [ ] Fix: Remover referências hardcoded a 'velociraptor'
- [ ] Fix: Atualizar paths de playbooks movidos
- [ ] Fix: Adicionar dconf_package e python_psutil_package no Darwin.yml
- [ ] Fix: Corrigir bootstrap.sh lógica de chown
- [ ] Fix: Recriar ou remover task de logrotate
- [ ] Fix: Corrigir condição de ansible-pull quando vault não existe
- [ ] Fix: Atualizar local.yml para usar grupo 'workstation' ao invés de 'localhost'
- [ ] Enhancement: Criar .github/workflows/test-macos.yml
- [ ] Enhancement: Criar Dockerfile.test
- [ ] Enhancement: Documentar setup inicial (.vault_key, chaves SSH)
- [ ] Security: Mover telegram_token para Ansible Vault
```

---

**Conclusão:** O projeto tem uma base sólida mas precisa de correções antes de executar em produção. Recomendo fortemente implementar o GitHub Actions para testes automatizados antes de rodar na sua máquina real.