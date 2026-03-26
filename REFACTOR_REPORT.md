# Relatório de Refatoração - Ansible neonet

## Resumo
Refatoração completa do projeto Ansible de multi-host Linux para macOS-only (tgworkstation).

## Métricas de Redução

| Métrica | Antes | Depois | Redução |
|---------|-------|--------|---------|
| Arquivos na raiz | 43 | ~35 | 18.6% |
| Linhas ansible.cfg | 519 | 24 | 95.4% |
| Linhas Brewfile | 574 | 563 | 1.9% |
| Roles | 4 | 2 | 50% |
| Playbooks | 3 | 1 | 66.7% |
| Linux-specific files | 0 (misturados) | 65+ (organizados em linux/) | N/A |

## Alterações Principais

### 1. Estrutura de Diretórios
- ✅ Criado diretório `linux/` com todos os arquivos Linux-specific
- ✅ Movidos: packages*.txt, pkglist.txt, modules/, collections/
- ✅ Movidos: install.sh, install-linux.sh, lib_sh/, lib_node/
- ✅ Movidos: roles/server/, roles/laxd.vnc/
- ✅ Movidos: site.yml, vnc.yml, host_vars/crworkstation.local, group_vars/eos.yml

### 2. Playbooks
- ✅ Simplificado `local.yml` de 71 para 24 linhas
- ✅ Removido bloco `hosts: server`
- ✅ Removidos pre_tasks com pacman/apt
- ✅ Removidos tasks de cleanup apt

### 3. Configuração
- ✅ Reduzido `ansible.cfg` de 519 para 24 linhas
- ✅ Atualizado path `vault_password_file` para `/Users/tg/.vault_key`
- ✅ Removidos comentários padrão do Ansible

### 4. Roles
- ✅ Criado `roles/base/vars/Darwin.yml`
- ✅ Criado `roles/workstation/vars/Darwin.yml`
- ✅ Adicionados guards `when: ansible_distribution != "Darwin"` para tasks Linux-only
- ✅ Atualizado `provision.sh.j2` com paths macOS

### 5. Scripts
- ✅ Corrigido `bootstrap.sh`: removido pacman, atualizado hostname detection
- ✅ Corrigido `update.sh`: syntax brew moderno
- ✅ Limpo `tweak-system-root.sh`: removido apps inexistentes no Sonoma
- ✅ Limpo Brewfile: removido pacotes obsoletos

## Validação
- ✅ Todos scripts passam em `bash -n` (syntax check)
- ✅ `local.yml` é YAML válido
- ✅ Zero referências a `/home/` sem guards
- ✅ Zero referências Linux sem guards

## Commits
1. `chore: create pre-macos-refactor backup tag`
2. `refactor: move Linux-specific files to linux/ directory`
3. `refactor: simplify local.yml for single-host macOS`
4. `refactor: clean and reduce ansible.cfg from 519 to 24 lines`
5. `refactor: adapt Ansible roles and config for macOS`
6. `refactor: update shell scripts for macOS`

## Próximos Passos
1. Testar ansible-pull na tgworkstation
2. Verificar se todas as tasks de provisionamento funcionam no macOS
3. Ajustar Brewfile conforme necessidade real do usuário

---
Gerado em: $(date)
