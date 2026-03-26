# Task 2: Reference Audit Report

## Summary
Auditoria completa das referências cruzadas no projeto Ansible neonet.

## Arquivos a Mover/Remover e Suas Referências

### 1. Package Lists (Linux-only)
**Arquivos**: packages.txt, packages_aur.txt, packages_flatpack.txt, packages_pip.txt, pkglist.txt

**Referenciados por**:
- `roles/base/tasks/software/packages_pacman.yml:3,10` - lookup('file', 'packages.txt')
- `roles/workstation/tasks/software/packages_pacman.yml:3,10` - lookup('file', 'packages.txt')

**Status**: SEGURO MOVER
- Ambos os arquivos acima serão desativados/comentados (T4)
- Nenhuma referência ativa após T4

---

### 2. Modules e Collections (Linux-only)
**Arquivos**: modules/aur.py, collections/requirements.yml

**Referenciados por**:
- `ansible.cfg:18` - library = ./modules:...
- `roles/*/tasks/software/packages_pacman.yml` - usa módulo `aur`

**Status**: SEGURO MOVER
- ansible.cfg será limpo (T14)
- packages_pacman.yml será desativado (T4)

---

### 3. Scripts Linux
**Arquivos**: install.sh, install-linux.sh, lib_sh/, lib_node/

**Referenciados por**:
- `bootstrap.sh:5` - chama install-darwin.sh (INEXISTENTE)
- `install.sh:5,8` - dispatch para install-darwin.sh ou install-linux.sh

**Status**: SEGURO MOVER
- install.sh não é usado em produção (bootstrap.sh tenta chamar install-darwin.sh que não existe)
- lib_sh/ é usado apenas por install-linux.sh

---

### 4. Roles Linux-only
**Arquivos**: roles/server/, roles/laxd.vnc/

**Referenciados por**:
- `local.yml:36-40` - hosts: server, roles: server
- `vnc.yml:6` - role: laxd.vnc

**Status**: SEGURO MOVER
- local.yml será simplificado (T10) - bloco server será removido
- vnc.yml será movido para linux/ (T7)

---

### 5. Playbooks e Vars Obsoletas
**Arquivos**: site.yml, host_vars/crworkstation.local/, group_vars/eos.yml

**Referenciados por**:
- site.yml: NÃO referenciado por nenhum playbook
- crworkstation.local: Host não existe no inventory
- eos.yml: Grupo não existe no inventory

**Status**: SEGURO MOVER
- Nenhuma referência ativa

---

### 6. Arquivos Temporários
**Arquivos**: asdd, gopass-client.py.new, tobeadded.txt, .crontab, retry/

**Referenciados por**:
- retry/: Referenciado por ansible.cfg:273

**Status**: SEGURO MOVER/DELETAR
- retry_files_enabled = False (já desativado)
- ansible.cfg será limpo (T14)

---

## Duplicações Identificadas

### 1. packages_pacman.yml
- `roles/base/tasks/software/packages_pacman.yml`
- `roles/workstation/tasks/software/packages_pacman.yml`

**Análise**: IDÊNTICOS (comparação visual confirmada)
- Ambos fazem lookup de packages.txt e packages_aur.txt
- Ambos são Linux-only (pacman/aur)
- Ação: Ambos serão desativados (T4) - não relevante para macOS

---

## Referências Que PRECISAM de Atualização

### 1. local.yml
**Linhas afetadas**:
- 2-21: pre_tasks com pacman/apt (remover)
- 24-40: hosts all + workstation + server (simplificar)
- 46-58: apt cleanup tasks (remover)
- 60-70: send alerts (verificar se são Linux-only)

**Ação**: T10 - Simplificar para single-host macOS

---

### 2. hosts
**Linhas afetadas**:
- 5: runner (remover - host não usado)
- 7: [server] (remover - grupo vazio)

**Ação**: T8 - Simplificar inventory

---

### 3. roles/base/tasks/main.yml
**Imports Linux-only**:
- `software/repositories.yml` - pacman/apt
- `software/packages_development.yml` - package module genérico
- `system_setup/bluetooth.yml` - Linux config
- `system_setup/locale.yml` - Linux locale
- `system_setup/memory.yml` - Linux swap
- `system_setup/microcode.yml` - Intel/AMD microcode
- `system_setup/openssh.yml` - sshd_config

**Ação**: T11 - Adicionar when: ansible_distribution != "Darwin"

---

### 4. roles/workstation/tasks/main.yml
**Imports Linux-only**:
- `desktop_environments/mate/main.yml` - MATE (Linux-only)
- `desktop_environments/gnome/main.yml` - GNOME (Linux-only)
- `software/packages_pacman.yml` - pacman/aur (mover T4)

**Ação**: T12 - Adicionar when guards

---

## Dependências de Tasks

```
T1 (tag) → T2 (auditoria) → T3 (baseline)
                           ↓
                    T4-T9 (moves em paralelo)
                           ↓
               T10 (local.yml simplificado)
                           ↓
               T11 (base Darwin) → T13 (provision.sh)
               T12 (workstation Darwin) → T20 (validação)
```

---

## Conclusão

**Pode mover SEM atualização**: Todos os arquivos Linux-only listados
**Precisa atualização ANTES**: local.yml, hosts, roles/*/main.yml
**Seguro deletar**: Arquivos temporários

Nenhuma referência crítica bloqueia a Wave 2 (moves).
