# Refatoração Ansible neonet — macOS-only (tgworkstation)

## TL;DR

> **Resumo**: Refatorar projeto Ansible legado de multi-host Linux para gerenciar APENAS tgworkstation (macOS 14 Sonoma) com ansible-pull via cron (usuário velociraptor). Mover tudo Linux para `linux/`, eliminar código morto, simplificar drasticamente.
> 
> **Entregáveis**:
> - Raiz limpa com apenas arquivos macOS-relevantes
> - Diretório `linux/` com tudo que é Linux-specific
> - Roles adaptados para macOS (Darwin vars)
> - provision.sh funcionando no macOS
> - Brewfile com syntax moderno
> - Playbook principal simplificado para single-host
> - Relatório de redução (antes/depois)
> 
> **Esforço Estimado**: Medium
> **Execução Paralela**: YES — 4 waves
> **Caminho Crítico**: T1 (tag) → T2 (auditoria) → T3-T7 (moves paralelos) → T8-T11 (adaptação) → T12-T15 (scripts) → T16 (validação) → T17 (relatório)

---

## Context

### Pedido Original
Refatorar o projeto Ansible neonot para orquestração via ansible-pull em modo pull, bem estruturada, com pouca repetição de código. Gerenciar apenas a máquina tgworkstation (macOS). Mover tudo Linux para `linux/`. Simplificar ao máximo. Remover o que não está mais disponível ou necessário. Entregar relatório de redução.

### Resumo da Entrevista
**Decisões Chave**:
- **Alvo único**: tgworkstation (macOS 14 Sonoma)
- **Agendamento**: cron (manter padrão do Linux)
- **Usuário ansible-pull**: velociraptor (adaptar paths `/home/` → `/Users/`)
- **Brewfile**: Limpar syntax (`brew cask` → `brew install --cask`) + revisar pacotes
- **Scripts a manter**: tweak-system-root.sh, bootstrap.sh, scripts/, run.sh, update.sh
- **Scripts a mover**: install.sh, install-linux.sh, lib_sh/ → `linux/`
- **Validação**: `ansible-playbook --check --diff`

**Descobertas da Análise**:
- `group_vars/all` contém telegram token em cleartext (documentar, não corrigir nesta refatoração)
- `packages_pacman.yml` duplicado identicamente em `base/` e `workstation/`
- `roles/base/tasks/users/user.yml` tem 342 linhas, ~50% código comentado
- Nenhum role tem vars para `Darwin`/`macOS` — só Debian/Fedora/Arch/Ubuntu/Mint/Pop!_OS
- Workstation role contém GNOME/MATE desktop environments (Linux-only)
- `Brewfile` (574 linhas) usa syntax depreciado `brew cask`
- `provision.sh.j2` tem paths hardcoded `/home/`
- `ansible_setup.yml` referencia `dconf_package` e `python_psutil_package` (Linux-only)
- Cron setup usa `cronie` systemd service (Linux-only)

### Análise Metis
**Gaps Identificados e Endereçados**:
- Backup: git tag `pre-macos-refactor` antes de qualquer mudança (T1)
- Validação de estado atual antes de modificar (T2)
- Guardrails: nunca deletar diretamente, sempre mover para `linux/` primeiro
- Criar Darwin.yml para cada role que carrega `{{ ansible_distribution }}.yml`
- Tokens de segurança: documentar mas não incluir no escopo desta refatoração
- Validação por fases com dry-run (T16)

---

## Work Objectives

### Objetivo Central
Transformar o projeto Ansible neonet de um setup multi-host Linux+macOS legado em uma configuração enxuta que gerencia exclusivamente tgworkstation (macOS 14 Sonoma) via ansible-pull.

### Entregáveis Concretos
- `linux/` contendo todos arquivos Linux-specific
- `local.yml` simplificado para single-host macOS
- `roles/base/vars/Darwin.yml` e `roles/workstation/vars/Darwin.yml`
- `provision.sh.j2` adaptado para paths macOS
- `Brewfile` com syntax moderno
- `bootstrap.sh` corrigido (remove referência a `install-darwin.sh` inexistente)
- `update.sh` com syntax brew moderno
- `ansible.cfg` reduzido de 519 para <100 linhas
- Relatório de redução em `REFACTOR_REPORT.md`

### Definição de Pronto
- [ ] `ansible-playbook --check --diff local.yml` executa sem erros fatais
- [ ] Nenhuma referência a `/home/` em playbooks ativos
- [ ] Nenhum playbook ativo referencia `apt`, `pacman`, `systemd`, `cronie`
- [ ] `linux/` contém todos arquivos Linux-specific
- [ ] Raiz não contém arquivos Linux-only
- [ ] Brewfile passa em `brew bundle check`

### Must Have
- ansible-pull funcionando no macOS via cron como usuário velociraptor
- Roles com Darwin vars para tasks que carregam distro-specific
- provision.sh com paths `/Users/` corretos
- Brewfile com syntax `brew install --cask`
- Remoção completa de: site.yml, vnc.yml, roles/laxd.vnc/, roles/server/, host_vars/crworkstation.local/, group_vars/eos.yml
- `local.yml` simplificado sem grupos `server` ou multi-host

### Must NOT Have (Guardrails)
- **NÃO adicionar** novos features macOS — apenas adaptar existente
- **NÃO reescrever** do zero — refatoração incremental
- **NÃO deletar** arquivos diretamente — sempre mover para `linux/`
- **NÃO migrar** segredos para vault — fora de escopo
- **NÃO criar** novos roles — adaptar existentes
- **NÃO adicionar** testes automatizados além do dry-run
- **NÃO alterar** behavior do código que funciona — apenas corrigir syntax e paths
- **NÃO incluir** instruções "enquanto estamos nisso" — foco estrito em simplificação macOS-only

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — Toda verificação é agent-executed.

### Decisão de Teste
- **Infraestrutura existe**: NO (Ansible existente é para Linux)
- **Testes automatizados**: NO
- **Framework**: N/A
- **Validação**: `ansible-playbook --check --diff` + syntax checks de scripts

### Política de QA
Cada task inclui cenários de QA agent-executed.
Evidence salva em `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **YAML/Ansible**: Bash — `ansible-playbook --check --diff`, `ansible-lint`
- **Shell Scripts**: Bash — `bash -n` (syntax check), `shellcheck`
- **Brewfile**: Bash — `brew bundle check` (dry-run)
- **Estrutura**: Bash — `grep`, `find` para verificar ausência de referências quebradas

---

## Execution Strategy

### Waves de Execução Paralela

```
Wave 1 (Start Immediately — backup + auditoria):
├── Task 1: Criar git tag de backup [quick]
├── Task 2: Auditoria completa de referências [deep]
└── Task 3: Documentar estado atual (linhas/arquivos) [quick]

Wave 2 (After Wave 1 — movers paralelos, MAX PARALLEL):
├── Task 4: Mover package lists Linux para linux/ [quick]
├── Task 5: Mover modules/collections Linux para linux/ [quick]
├── Task 6: Mover scripts Linux para linux/ [quick]
├── Task 7: Mover roles Linux-only para linux/ [quick]
├── Task 8: Mover playbooks/host_vars/group_vars Linux para linux/ [quick]
└── Task 9: Limpar root — remover arquivos temporários [quick]

Wave 3 (After Wave 2 — adaptação macOS, DEPENDENTES):
├── Task 10: Simplificar local.yml para single-host macOS [unspecified-high]
├── Task 11: Adaptar roles/base para macOS (Darwin vars) [deep]
├── Task 12: Adaptar roles/workstation para macOS (Darwin vars) [deep]
├── Task 13: Adaptar provision.sh.j2 para macOS [quick]
├── Task 14: Limpar e reduzir ansible.cfg (519 → <100 linhas) [quick]
└── Task 15: Adaptar cron setup para macOS [quick]

Wave 4 (After Wave 3 — scripts + validação):
├── Task 16: Corrigir bootstrap.sh [quick]
├── Task 17: Atualizar Brewfile syntax + revisão [unspecified-high]
├── Task 18: Atualizar update.sh syntax brew [quick]
├── Task 19: Limpar tweak-system-root.sh [quick]
└── Task 20: Validação final — dry-run + relatório [unspecified-high]

Wave FINAL (After ALL tasks — 2 reviews paralelos):
├── Task F1: Audit de conformidade com plano (oracle)
└── Task F2: Relatório de redução final (unspecified-high)

Critical Path: T1 → T2 → T4-T9 (paralelos) → T10 → T11 → T13 → T16 → T20 → F1-F2
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 6 (Wave 2)
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1 | — | 2, 3, 4-9 | 1 |
| 2 | 1 | 4-8, 10-13 | 1 |
| 3 | 1 | 20 | 1 |
| 4 | 2 | 10, 11 | 2 |
| 5 | 2 | 11 | 2 |
| 6 | 2 | — | 2 |
| 7 | 2 | 10, 11, 12 | 2 |
| 8 | 2 | 10, 11, 12 | 2 |
| 9 | 2 | — | 2 |
| 10 | 2, 4, 7, 8 | 20 | 3 |
| 11 | 2, 4, 5, 7 | 13, 20 | 3 |
| 12 | 2, 7, 8 | 20 | 3 |
| 13 | 11 | 20 | 3 |
| 14 | 2 | 20 | 3 |
| 15 | 11 | 20 | 3 |
| 16 | 2 | 20 | 4 |
| 17 | 2 | 20 | 4 |
| 18 | 2 | 20 | 4 |
| 19 | 2 | 20 | 4 |
| 20 | 3, 10-19 | F1, F2 | 4 |
| F1 | 20 | — | FINAL |
| F2 | 3, 20 | — | FINAL |

### Agent Dispatch Summary

- **Wave 1**: 3 — T1 → `quick`, T2 → `deep`, T3 → `quick`
- **Wave 2**: 6 — T4-T9 → `quick` (todos)
- **Wave 3**: 6 — T10 → `unspecified-high`, T11-T12 → `deep`, T13-T15 → `quick`
- **Wave 4**: 5 — T16,T18,T19 → `quick`, T17 → `unspecified-high`, T20 → `unspecified-high`
- **FINAL**: 2 — F1 → `oracle`, F2 → `unspecified-high`

---

## TODOs

- [x] 1. Criar git tag de backup pre-macos-refactor

  **What to do**:
  - Criar git tag `pre-macos-refactor` no commit atual
  - Garantir working tree limpa (commit ou stash antes)
  - Este tag permite rollback completo se necessário

  **Must NOT do**:
  - Não fazer nenhuma modificação de arquivos nesta task
  - Não push do tag (local only por enquanto)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: NO (deve ser o primeiro)
  - **Parallel Group**: Wave 1 (sequential start)
  - **Blocks**: T2, T3, T4-T9
  - **Blocked By**: None

  **References**:
  - Git CLI: `git tag -a pre-macos-refactor -m "backup before macOS-only refactor"`

  **Acceptance Criteria**:
  - [ ] `git tag -l pre-macos-refactor` retorna o tag
  - [ ] `git show pre-macos-refactor --stat` mostra commit atual

  **QA Scenarios**:
  ```
  Scenario: Tag criado com sucesso
    Tool: Bash
    Steps:
      1. git tag -l pre-macos-refactor
      2. Assert output contains "pre-macos-refactor"
    Expected Result: Tag existe localmente
    Evidence: .sisyphus/evidence/task-1-tag-created.txt

  Scenario: Tag aponta para commit correto
    Tool: Bash
    Steps:
      1. git rev-parse pre-macos-refactor
      2. git rev-parse HEAD
      3. Assert both outputs are identical
    Expected Result: Tag aponta para HEAD atual
    Evidence: .sisyphus/evidence/task-1-tag-commit.txt
  ```

  **Commit**: YES (independente)
  - Message: `chore: create pre-macos-refactor backup tag`

---

- [x] 2. Auditoria completa de referências entre arquivos

  **What to do**:
  - Mapear TODAS as referências cruzadas no projeto
  - Para cada arquivo a ser movido/deletado: encontrar quem o referencia
  - Documentar em `.sisyphus/evidence/task-2-reference-audit.md`:
    - Quais arquivos são referenciados por quais
    - Quais podem ser movidos sem quebrar nada
    - Quais precisam de atualização de referência antes do move
  - Verificar: imports, includes, copy src, template src, with_file, lookup file
  - Identificar tasks duplicados entre roles

  **Must NOT do**:
  - Não modificar nenhum arquivo
  - Não mover nem deletar nada

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (depois de T1)
  - **Parallel Group**: Wave 1 (after T1)
  - **Blocks**: T4-T8, T10-T13
  - **Blocked By**: T1

  **References**:
  - `roles/base/tasks/main.yml` — Importa tasks de software/ e system_setup/
  - `roles/workstation/tasks/main.yml` — Importa desktop_environments/ e software/
  - `roles/base/tasks/software/packages_pacman.yml` — Duplicado em workstation
  - `roles/base/tasks/users/user.yml:50-342` — 290+ linhas com código comentado
  - `local.yml` — Referencia roles base, workstation, server; usa apt, pacman
  - `hosts` — Inventory com grupos workstation e server
  - `group_vars/all` — Variáveis globais incluindo upstream repo URL
  - `roles/base/templates/provision.sh.j2` — Template do provision.sh com paths /home/

  **Acceptance Criteria**:
  - [ ] Documento `.sisyphus/evidence/task-2-reference-audit.md` gerado
  - [ ] Lista completa de arquivos e suas referências
  - [ ] Marcação clara: seguro mover / precisa atualizar / bloqueado

  **QA Scenarios**:
  ```
  Scenario: Documento de auditoria gerado
    Tool: Bash
    Steps:
      1. test -f .sisyphus/evidence/task-2-reference-audit.md
    Expected Result: Arquivo existe e não está vazio (>100 linhas)
    Evidence: .sisyphus/evidence/task-2-audit-exists.txt
  ```

  **Commit**: NO

---

- [x] 3. Documentar estado atual (baseline para relatório de redução)

  **What to do**:
  - Contar e registrar métricas do estado atual do projeto:
    - Total de arquivos na raiz (`ls -1 | wc -l`)
    - Total de linhas em todos arquivos (`find . -not -path './.git/*' -type f | xargs wc -l`)
    - Total de arquivos em roles/ (`find roles/ -type f | wc -l`)
    - Total de playbooks (`find . -name '*.yml' | grep -E '(local|site|vnc)' | wc -l`)
    - Linhas em ansible.cfg (`wc -l ansible.cfg`)
    - Linhas em Brewfile (`wc -l Brewfile`)
    - Total de roles (`ls -d roles/*/ | wc -l`)
    - Total de scripts em scripts/ (`ls scripts/ | wc -l`)
    - Total de linhas em packages*.txt e pkglist.txt
  - Salvar em `.sisyphus/evidence/task-3-baseline.txt`

  **Must NOT do**:
  - Não modificar nada

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T2, ambos depois de T1)
  - **Parallel Group**: Wave 1
  - **Blocks**: T20, F2
  - **Blocked By**: T1

  **References**:
  - Todos os arquivos do projeto

  **Acceptance Criteria**:
  - [ ] `.sisyphus/evidence/task-3-baseline.txt` contém todas as métricas
  - [ ] Valores são numéricos e fazem sentido

  **QA Scenarios**:
  ```
  Scenario: Baseline documentado
    Tool: Bash
    Steps:
      1. test -f .sisyphus/evidence/task-3-baseline.txt
      2. grep -c "^[0-9]" .sisyphus/evidence/task-3-baseline.txt
    Expected Result: Arquivo existe com múltiplas linhas de métricas numéricas
    Evidence: .sisyphus/evidence/task-3-baseline-verify.txt
  ```

  **Commit**: NO

---

- [x] 4. Mover package lists Linux para linux/

  **What to do**:
  - Criar diretório `linux/`
  - Mover para `linux/`:
    - `packages.txt` → `linux/packages.txt`
    - `packages_aur.txt` → `linux/packages_aur.txt`
    - `packages_flatpack.txt` → `linux/packages_flatpack.txt`
    - `packages_pip.txt` → `linux/packages_pip.txt`
    - `pkglist.txt` → `linux/pkglist.txt`
  - Remover referências a estes arquivos em playbooks ativos:
    - `roles/workstation/tasks/software/packages_pacman.yml` — referencia packages.txt e packages_aur.txt
    - `roles/base/tasks/software/packages_pacman.yml` — referencia packages.txt e packages_aur.txt
  - Usar `git mv` para preservar histórico

  **Must NOT do**:
  - Não deletar os arquivos sem git mv
  - Não mover Brewfile (é macOS)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T5-T9 na Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: T10, T11
  - **Blocked By**: T2

  **References**:
  - `packages.txt` — 371 linhas, Arch Linux packages
  - `packages_aur.txt` — 153 linhas, AUR packages
  - `packages_flatpack.txt` — 2 linhas
  - `packages_pip.txt` — 2 linhas
  - `pkglist.txt` — 458 linhas, Arch pkglist
  - `roles/workstation/tasks/software/packages_pacman.yml:3,10` — `lookup('file', 'packages.txt')`, `lookup('file', 'packages_aur.txt')`
  - `roles/base/tasks/software/packages_pacman.yml:3,10` — Mesmas referências

  **Acceptance Criteria**:
  - [ ] `ls linux/packages.txt linux/packages_aur.txt linux/packages_flatpack.txt linux/packages_pip.txt linux/pkglist.txt` — todos existem
  - [ ] `ls packages.txt packages_aur.txt packages_flatpack.txt packages_pip.txt pkglist.txt` — nenhum existe na raiz
  - [ ] `grep -r "packages.txt" roles/ --include="*.yml"` — sem output (referências removidas)

  **QA Scenarios**:
  ```
  Scenario: Arquivos movidos corretamente
    Tool: Bash
    Steps:
      1. ls linux/packages.txt linux/packages_aur.txt linux/packages_flatpack.txt linux/packages_pip.txt linux/pkglist.txt 2>&1
      2. Assert all files exist
    Expected Result: 5 arquivos existem em linux/
    Evidence: .sisyphus/evidence/task-4-moved-files.txt

  Scenario: Referências removidas dos roles
    Tool: Bash
    Steps:
      1. grep -rn "packages\.txt\|packages_aur\.txt\|pkglist\.txt" roles/ --include="*.yml"
    Expected Result: Nenhuma referência encontrada
    Evidence: .sisyphus/evidence/task-4-no-references.txt
  ```

  **Commit**: YES (grupo com T5-T9)
  - Message: `refactor: move Linux-specific files to linux/ directory`
  - Pre-commit: `bash -n` nos scripts movidos

---

- [x] 5. Mover modules e collections Linux para linux/

  **What to do**:
  - Mover para `linux/`:
    - `modules/aur.py` → `linux/modules/aur.py`
    - `collections/requirements.yml` → `linux/collections/requirements.yml`
  - Remover referências a `kewlfft.aur` collection se existirem em playbooks ativos
  - Usar `git mv`

  **Must NOT do**:
  - Não deletar sem git mv

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T4, T6-T9 na Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: T11
  - **Blocked By**: T2

  **References**:
  - `modules/aur.py` — Custom Ansible module para AUR (Arch Linux)
  - `collections/requirements.yml` — Contém `kewlfft.aur` (Arch User Repository)
  - `ansible.cfg:18` — `library = ./modules:...` — precisa atualizar path

  **Acceptance Criteria**:
  - [ ] `ls linux/modules/aur.py linux/collections/requirements.yml` — existem
  - [ ] `ls modules/aur.py` — não existe na raiz
  - [ ] `ansible.cfg` não referencia `./modules` se modules está vazio

  **QA Scenarios**:
  ```
  Scenario: Modules movidos
    Tool: Bash
    Steps:
      1. ls linux/modules/aur.py 2>&1
      2. test ! -f modules/aur.py
    Expected Result: Arquivo existe em linux/ e não na raiz
    Evidence: .sisyphus/evidence/task-5-modules-moved.txt

  Scenario: ansible.cfg atualizado
    Tool: Bash
    Steps:
      1. grep "modules" ansible.cfg
      2. Assert path reflete novo local ou módulos locais não são necessários
    Expected Result: Sem referência a ./modules na raiz
    Evidence: .sisyphus/evidence/task-5-ansible-cfg.txt
  ```

  **Commit**: YES (grupo com T4-T9)

---

- [x] 6. Mover scripts Linux para linux/

  **What to do**:
  - Mover para `linux/`:
    - `install.sh` → `linux/install.sh`
    - `install-linux.sh` → `linux/install-linux.sh`
    - `lib_sh/` → `linux/lib_sh/`
    - `lib_node/` → `linux/lib_node/`
  - Usar `git mv`

  **Must NOT do**:
  - Não mover `bootstrap.sh`, `update.sh`, `tweak-system-root.sh`, `run.sh` (são usados no macOS)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T4-T5, T7-T9 na Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: T2

  **References**:
  - `install.sh` — Dispatch script que chama install-darwin.sh (inexistente) ou install-linux.sh
  - `install-linux.sh` — 194 linhas, instalação Linux (Arch/Debian/Ubuntu)
  - `lib_sh/echos.sh` — Helper scripts (bot, ok, running) usados por install-linux.sh
  - `lib_sh/requirers.sh` — Helper requirements
  - `lib_node/command.js` — Node.js helper

  **Acceptance Criteria**:
  - [ ] `ls linux/install.sh linux/install-linux.sh linux/lib_sh/ linux/lib_node/` — existem
  - [ ] `ls install.sh install-linux.sh lib_sh/` — não existem na raiz

  **QA Scenarios**:
  ```
  Scenario: Scripts Linux movidos
    Tool: Bash
    Steps:
      1. test -f linux/install.sh && test -f linux/install-linux.sh && test -d linux/lib_sh
    Expected Result: Todos existem em linux/
    Evidence: .sisyphus/evidence/task-6-scripts-moved.txt

  Scenario: Scripts macOS mantidos
    Tool: Bash
    Steps:
      1. test -f bootstrap.sh && test -f update.sh && test -f tweak-system-root.sh && test -f run.sh
    Expected Result: Todos ainda existem na raiz
    Evidence: .sisyphus/evidence/task-6-macos-scripts-kept.txt
  ```

  **Commit**: YES (grupo com T4-T9)

---

- [x] 7. Mover roles Linux-only para linux/

  **What to do**:
  - Mover para `linux/roles/`:
    - `roles/server/` → `linux/roles/server/` (grupo server vazio no inventory)
    - `roles/laxd.vnc/` → `linux/roles/laxd.vnc/` (VNC Linux-only, Galaxy role)
  - Remover referências nos playbooks:
    - `local.yml:36-40` — Bloco `hosts: server` com role server
    - `vnc.yml` — Deve ser movido para `linux/vnc.yml`
  - Usar `git mv`

  **Must NOT do**:
  - Não mover `roles/base/` ou `roles/workstation/` (são usados no macOS, precisam adaptação)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T4-T6, T8-T9 na Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: T10, T11, T12
  - **Blocked By**: T2

  **References**:
  - `roles/server/` — 25+ arquivos: NRPE, UFW, QEMU agent, unattended upgrades — tudo Linux
  - `roles/laxd.vnc/` — Galaxy role para VNC server — Linux-only
  - `local.yml:36-40` — `hosts: server; roles: - server`
  - `vnc.yml` — Playbook VNC, referencia `laxd.vnc` role
  - `hosts:7` — `[server]` grupo vazio

  **Acceptance Criteria**:
  - [ ] `ls linux/roles/server/ linux/roles/laxd.vnc/ linux/vnc.yml` — existem
  - [ ] `ls roles/server/ roles/laxd.vnc/ vnc.yml` — não existem na raiz
  - [ ] `local.yml` não contém bloco `hosts: server`

  **QA Scenarios**:
  ```
  Scenario: Roles Linux movidos
    Tool: Bash
    Steps:
      1. test -d linux/roles/server && test -d linux/roles/laxd.vnc && test -f linux/vnc.yml
    Expected Result: Diretórios e arquivo existem em linux/
    Evidence: .sisyphus/evidence/task-7-roles-moved.txt

  Scenario: VNC playbook movido
    Tool: Bash
    Steps:
      1. test ! -f vnc.yml
    Expected Result: vnc.yml não existe na raiz
    Evidence: .sisyphus/evidence/task-7-vnc-moved.txt
  ```

  **Commit**: YES (grupo com T4-T9)

---

- [x] 8. Mover playbooks/host_vars/group_vars Linux para linux/

  **What to do**:
  - Mover para `linux/`:
    - `site.yml` → `linux/site.yml` (debug test, não é usado em produção)
    - `host_vars/crworkstation.local/` → `linux/host_vars/crworkstation.local/` (host não existe)
    - `group_vars/eos.yml` → `linux/group_vars/eos.yml` (grupo/host não existe)
  - Atualizar `hosts` inventory:
    - Remover `crworkstation.local` (não existe como host real)
    - Remover `[server]` grupo vazio
    - Simplificar para apenas `[workstation]` com `tgworkstation.local`
  - Remover `playbooks/send_completion_alert.yml` e `playbooks/send_failure_alert.yml` se contêm Linux-only references (verificar primeiro)
  - Usar `git mv`

  **Must NOT do**:
  - Não mover `local.yml` (é o playbook principal, será adaptado em T10)
  - Não mover `host_vars/tgworkstation.local/` (é o host alvo)
  - Não mover `group_vars/all` (variáveis globais são necessárias)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T4-T7, T9 na Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: T10, T11, T12
  - **Blocked By**: T2

  **References**:
  - `site.yml` — Apenas debug test com passwordstore lookup, não produção
  - `hosts` — 7 linhas, contém `crworkstation.local` e `[server]` vazio
  - `host_vars/crworkstation.local` — Referencia blog/site da Camila (não nosso host)
  - `group_vars/eos.yml` — `ansible_user: tg`, grupo não existe no inventory
  - `local.yml:36-40` — Referencia `hosts: server`
  - `playbooks/send_completion_alert.yml` — Verificar se tem Linux-only (telegram notification)

  **Acceptance Criteria**:
  - [ ] `ls linux/site.yml linux/host_vars/crworkstation.local linux/group_vars/eos.yml` — existem
  - [ ] `ls site.yml` — não existe na raiz
  - [ ] `hosts` contém apenas `[workstation]` com `tgworkstation.local`
  - [ ] `local.yml` não referencia `hosts: server` nem `crworkstation`

  **QA Scenarios**:
  ```
  Scenario: Inventory simplificado
    Tool: Bash
    Steps:
      1. cat hosts
      2. Assert contém apenas [workstation] e tgworkstation.local
      3. Assert não contém "crworkstation" nem "[server]"
    Expected Result: Inventory limpo com apenas workstation
    Evidence: .sisyphus/evidence/task-8-inventory.txt

  Scenario: Arquivos Linux movidos
    Tool: Bash
    Steps:
      1. test -f linux/site.yml && test -d linux/host_vars/crworkstation.local && test -f linux/group_vars/eos.yml
    Expected Result: Todos existem em linux/
    Evidence: .sisyphus/evidence/task-8-vars-moved.txt
  ```

  **Commit**: YES (grupo com T4-T9)

---

- [x] 9. Limpar root — remover arquivos temporários e desnecessários

  **What to do**:
  - Mover para `linux/` ou deletar arquivos temporários:
    - `asdd` → deletar (arquivo sem propósito)
    - `gopass-client.py.new` → deletar (arquivo temporário .new)
    - `tobeadded.txt` → deletar (arquivo de notas)
    - `.crontab` → mover para `linux/.crontab` (todo comentado, Linux-only)
    - `retry/` → `linux/retry/` (Ansible retry files, config em ansible.cfg aponta para `./retry`)
  - Atualizar `ansible.cfg` para não referenciar `./retry` (ou remover `retry_files_enabled` já está False)
  - Remover `HISTORY.md` e `TOOLS.md` se forem desatualizados e não relevantes para macOS (verificar antes)

  **Must NOT do**:
  - Não deletar dotfiles (.zshrc, .vimrc, etc.) — são a funcionalidade principal
  - Não deletar configs/ ou fonts/ — podem ser usados no macOS
  - Não deletar scripts/ — foi solicitado manter

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T4-T8 na Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: T2

  **References**:
  - `asdd` — Arquivo misterioso sem extensão
  - `gopass-client.py.new` — Arquivo temporário
  - `tobeadded.txt` — Lista de notas
  - `.crontab` — 2 linhas, tudo comentado
  - `retry/` — Diretório vazio ou com retry files antigos
  - `HISTORY.md` — Histórico de releases v1-v4 (2014-2016)
  - `ansible.cfg:273` — `retry_files_enabled = False; retry_files_save_path = ./retry`

  **Acceptance Criteria**:
  - [ ] `ls asdd gopass-client.py.new tobeadded.txt` — não existem na raiz
  - [ ] `ls .crontab` — não existe na raiz

  **QA Scenarios**:
  ```
  Scenario: Temp files removidos
    Tool: Bash
    Steps:
      1. ls asdd gopass-client.py.new tobeadded.txt .crontab 2>&1
    Expected Result: "No such file or directory" para todos
    Evidence: .sisyphus/evidence/task-9-temp-files-removed.txt
  ```

  **Commit**: YES (grupo com T4-T9)

---

- [ ] 10. Simplificar local.yml para single-host macOS

  **What to do**:
  - Reescrever `local.yml` para:
    - Um único play: `hosts: workstation` (ou `hosts: all` + inventory só tem workstation)
    - Remover bloco `hosts: server` com role server (já movido)
    - Remover pre_tasks de `apt update_cache` e `pacman update_cache` (Linux-only)
    - Remover tasks de cleanup `apt autoclean`/`autoremove` (Linux-only)
    - Remover `playbooks/send_completion_alert.yml` e `playbooks/send_failure_alert.yml` se Linux-only (ou adaptar)
    - Simplificar para apenas rodar roles base e workstation
  - Connection: `local` (já está correto)
  - Manter `become: true` para tasks que precisam de sudo

  **Must NOT do**:
  - Não adicionar novos plays ou features
  - Não mudar a funcionalidade dos roles

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (depende de T4, T7, T8)
  - **Parallel Group**: Wave 3
  - **Blocks**: T20
  - **Blocked By**: T2, T4, T7, T8

  **References**:
  - `local.yml` — Playbook atual (71 linhas) com 4 plays: pre_tasks (apt/pacman), base, workstation, server, cleanup
  - `hosts` — Inventory (será simplificado em T8)

  **Acceptance Criteria**:
  - [ ] `local.yml` não contém `hosts: server`
  - [ ] `local.yml` não contém `apt` ou `pacman`
  - [ ] `local.yml` não contém `autoclean` ou `autoremove`
  - [ ] `local.yml` referencia apenas roles `base` e `workstation`
  - [ ] `local.yml` tem syntax YAML válida

  **QA Scenarios**:
  ```
  Scenario: local.yml simplificado
    Tool: Bash
    Steps:
      1. grep -c "hosts: server" local.yml  # Expected: 0
      2. grep -cE "(apt|pacman|autoclean|autoremove)" local.yml  # Expected: 0
      3. grep -c "roles:" local.yml  # Expected: 2 (base + workstation)
    Expected Result: Nenhuma referência Linux, 2 roles
    Evidence: .sisyphus/evidence/task-10-local-yml.txt

  Scenario: YAML syntax válido
    Tool: Bash
    Steps:
      1. python3 -c "import yaml; yaml.safe_load(open('local.yml'))"
    Expected Result: Exit code 0, sem erros
    Evidence: .sisyphus/evidence/task-10-yaml-valid.txt
  ```

  **Commit**: YES (grupo T10-T15)
  - Message: `refactor: adapt Ansible roles and config for macOS`

---

- [ ] 11. Adaptar roles/base para macOS (Darwin vars)

  **What to do**:
  - Criar `roles/base/vars/Darwin.yml` com variáveis macOS:
    - `sudo_group: wheel` (macOS usa wheel, não sudo)
    - `cron_package: cron` (macOS tem cron built-in, ou vixie-cron via brew)
    - `shell_package:` (não necessário, zsh vem com macOS)
    - Remover/ignorar vars Linux-only: `dconf_package`, `python_psutil_package`, etc.
  - Adaptar tasks em `roles/base/tasks/`:
    - `main.yml`: Adicionar condicionais `when: ansible_distribution != "Darwin"` para tasks Linux-only:
      - `system_setup/microcode.yml` — Linux-only
      - `system_setup/bluetooth.yml` — Linux-only bluetooth config
      - `system_setup/locale.yml` — Linux-only locale
      - `system_setup/memory.yml` — Linux-only swap
      - `system_setup/openssh.yml` — Linux-only sshd_config
      - `software/repositories.yml` — Linux-only (pacman.conf, apt)
      - `software/packages_pacman.yml` — Linux-only (movido em T4)
      - `software/packages_development.yml` — Revisar se aplica ao macOS (brew em vez de package)
    - `ansible_setup.yml`: Adaptar para Homebrew em vez de `package` module:
      - Instalar ansible via brew se não presente
      - Remover referências a `dconf_package` e `python_psutil_package`
      - Remover logrotate config (Linux-only)
      - Remover referência a `/etc/ansible` (macOS paths diferentes)
      - Adaptar paths `/home/velociraptor` → `/Users/velociraptor`
  - Limpar código comentado em `users/user.yml` (~50% do arquivo é comentado)

  **Must NOT do**:
  - Não adicionar novas funcionalidades
  - Não mudar a lógica do bare repo git (funciona no macOS)
  - Não criar novos tasks — apenas adaptar existentes

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T12 na Wave 3, após T2, T4, T5, T7)
  - **Parallel Group**: Wave 3
  - **Blocks**: T13, T15, T20
  - **Blocked By**: T2, T4, T5, T7

  **References**:
  - `roles/base/vars/Archlinux.yml` — Exemplo de vars Linux para comparar
  - `roles/base/vars/Ubuntu.yml` — Exemplo de vars Linux para comparar
  - `roles/base/vars/main.yml` — Vars globais (vault encrypted)
  - `roles/base/tasks/main.yml` — 34 linhas, carrega distro vars e importa tasks
  - `roles/base/tasks/ansible_setup.yml` — 53 linhas, setup do ansible
  - `roles/base/tasks/users/user.yml` — 342 linhas, user setup + dotfiles (50% comentado)
  - `roles/base/tasks/software/repositories.yml` — 41 linhas, pacman/apt (Linux-only)
  - `roles/base/tasks/software/packages_development.yml` — 18 linhas, dev packages (Linux package manager)
  - `roles/base/tasks/system_setup/microcode.yml` — Intel/AMD microcode
  - `roles/base/tasks/system_setup/cron.yml` — Cron setup com cronie service

  **Acceptance Criteria**:
  - [ ] `roles/base/vars/Darwin.yml` existe com `sudo_group: wheel`
  - [ ] Nenhuma task em base/ referencia `pacman`, `apt`, `systemd`, `cronie` sem `when` guard
  - [ ] `ansible_setup.yml` não referencia `dconf_package`
  - [ ] `ansible_setup.yml` usa paths `/Users/` em vez de `/home/`
  - [ ] `users/user.yml` tem código comentado removido (<100 linhas)

  **QA Scenarios**:
  ```
  Scenario: Darwin vars criado
    Tool: Bash
    Steps:
      1. test -f roles/base/vars/Darwin.yml
      2. grep "wheel" roles/base/vars/Darwin.yml
    Expected Result: Arquivo existe e contém sudo_group: wheel
    Evidence: .sisyphus/evidence/task-11-darwin-vars.txt

  Scenario: Sem referências Linux sem guard
    Tool: Bash
    Steps:
      1. grep -rnE "(pacman|apt|systemd|cronie)" roles/base/tasks/ --include="*.yml"
      2. Para cada resultado, verificar se tem "when:" que exclui Darwin
    Expected Result: Todas referências Linux têm guard "when:"
    Evidence: .sisyphus/evidence/task-11-linux-guards.txt

  Scenario: Paths macOS corretos
    Tool: Bash
    Steps:
      1. grep -rn "/home/" roles/base/ --include="*.yml"
    Expected Result: Nenhuma referência a /home/ (ou apenas em when: ansible_distribution != "Darwin")
    Evidence: .sisyphus/evidence/task-11-no-home-paths.txt
  ```

  **Commit**: YES (grupo T10-T15)

---

- [ ] 12. Adaptar roles/workstation para macOS (Darwin vars)

  **What to do**:
  - Criar `roles/workstation/vars/Darwin.yml` com variáveis macOS:
    - Definir variáveis necessárias para tasks que sobrevivem no macOS
  - Adaptar/remover tasks:
    - `software/packages_pacman.yml` — MOVIDO em T4 (remover ou comentar import)
    - `software/browser_extensions.yml` — Verificar se aplica ao macOS (provavelmente sim)
    - `system_setup/autofs.yml` — Linux-only NFS autofs (remover ou comentar)
    - `system_setup/scripts.yml` — Verificar conteúdo
    - `desktop_environments/gnome/` — TODO Linux-only, adicionar `when: ansible_distribution != "Darwin"` ou remover import
    - `desktop_environments/mate/` — Mesmo (se existir import em main.yml)
    - `users/user.yml` — Verificar se duplica tasks de base/users (probavelmente sim, considerar remover)

  **Must NOT do**:
  - Não adicionar novos desktop environments
  - Não adicionar features macOS que não existiam antes

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T11 na Wave 3, após T2, T7, T8)
  - **Parallel Group**: Wave 3
  - **Blocks**: T20
  - **Blocked By**: T2, T7, T8

  **References**:
  - `roles/workstation/tasks/main.yml` — 27 linhas, importa users, gnome, mate, packages_pacman, browser_extensions
  - `roles/workstation/vars/Archlinux.yml` — Exemplo para comparar
  - `roles/workstation/tasks/desktop_environments/gnome/` — 10+ arquivos GNOME (Linux-only)
  - `roles/workstation/tasks/software/browser_extensions.yml` — Verificar conteúdo
  - `roles/workstation/tasks/software/packages_pacman.yml` — 18 linhas (movido em T4)

  **Acceptance Criteria**:
  - [ ] `roles/workstation/vars/Darwin.yml` existe
  - [ ] `main.yml` do workstation não importa GNOME/MATE sem `when` guard
  - [ ] `main.yml` do workstation não referencia `packages_pacman` (já movido)

  **QA Scenarios**:
  ```
  Scenario: Darwin vars workstation criado
    Tool: Bash
    Steps:
      1. test -f roles/workstation/vars/Darwin.yml
    Expected Result: Arquivo existe
    Evidence: .sisyphus/evidence/task-12-workstation-darwin.txt

  Scenario: Sem imports Linux sem guard
    Tool: Bash
    Steps:
      1. grep -n "gnome\|mate\|packages_pacman\|autofs" roles/workstation/tasks/main.yml
      2. Para cada, verificar if "when:" exclui Darwin
    Expected Result: Todos imports Linux têm guard
    Evidence: .sisyphus/evidence/task-12-workstation-guards.txt
  ```

  **Commit**: YES (grupo T10-T15)

---

- [ ] 13. Adaptar provision.sh.j2 para macOS

  **What to do**:
  - Atualizar `roles/base/templates/provision.sh.j2`:
    - Trocar paths `/home/` por `/Users/`:
      - `/home/${ANSIBLEUSER}` → `/Users/${ANSIBLEUSER}`
      - `/home/${LOCALUSER}` → `/Users/${LOCALUSER}`
    - Adicionar suporte para detectar se está em macOS e ajustar opções:
      - `--connection local` pode não ser necessário no macOS (already local)
    - Garantir que o log path `/var/log/ansible.log` funciona no macOS (precisa de sudo/touch)
    - Manter a lógica de `--only-if-changed` e tag support
    - Adicionar `set -euo pipefail` para safety
  - O provision script é deployado em `ansible_setup.yml` para `/usr/local/bin/provision`

  **Must NOT do**:
  - Não mudar a lógica principal do provision.sh (funciona bem)
  - Não mudar o nome do usuário velociraptor

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (depende de T11)
  - **Parallel Group**: Wave 3
  - **Blocks**: T20
  - **Blocked By**: T11

  **References**:
  - `roles/base/templates/provision.sh.j2` — 19 linhas, template do provision script
  - `roles/base/tasks/ansible_setup.yml:46-53` — Deploy do provision.sh para /usr/local/bin/provision

  **Acceptance Criteria**:
  - [ ] `provision.sh.j2` não contém `/home/`
  - [ ] `provision.sh.j2` contém `/Users/`
  - [ ] `bash -n` no template renderizado passa

  **QA Scenarios**:
  ```
  Scenario: Paths macOS no template
    Tool: Bash
    Steps:
      1. grep -c "/home/" roles/base/templates/provision.sh.j2  # Expected: 0
      2. grep -c "/Users/" roles/base/templates/provision.sh.j2  # Expected: >0
    Expected Result: Zero /home/, pelo menos uma /Users/
    Evidence: .sisyphus/evidence/task-13-template-paths.txt
  ```

  **Commit**: YES (grupo T10-T15)

---

- [ ] 14. Limpar e reduzir ansible.cfg (519 → <100 linhas)

  **What to do**:
  - Reduzir `ansible.cfg` de 519 para <100 linhas:
    - Remover TODOS os comentários padrão do Ansible (são 80% do arquivo)
    - Manter apenas settings ativamente configurados:
      - `interpreter_python = auto_silent`
      - `inventory = hosts`
      - `gathering = smart`
      - `roles_path = ./roles`
      - `host_key_checking = False`
      - `stdout_callback = yaml`
      - `fact_caching = memory`
      - `fact_caching_connection = /tmp`
      - `fact_caching_timeout = 7200`
      - `retry_files_enabled = False`
      - `vault_password_file = /home/tg/.vault_key` — ATUALIZAR para macOS path se necessário
      - `inventory_ignore_extensions`
      - `ignore_patterns`
      - `deprecation_warnings = False`
      - `log_path = ~/ansible.log`
      - `display_skipped_hosts = False`
      - `ssh_args` (se ainda necessário para local)
      - `pipelining = True`
      - `force_color = 1`
    - Remover seções inteiras vazias após limpeza
    - Atualizar path `vault_password_file` de `/home/tg/.vault_key` para macOS path
    - Atualizar `retry_files_save_path` de `./retry` (se `retry_files_enabled = False` já, pode remover)

  **Must NOT do**:
  - Não alterar settings que são funcionalmente necessários
  - Não adicionar novos settings

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T10-T13, T15 na Wave 3)
  - **Parallel Group**: Wave 3
  - **Blocks**: T20
  - **Blocked By**: T2

  **References**:
  - `ansible.cfg` — 519 linhas, arquivo INI com massiva documentação comentada

  **Acceptance Criteria**:
  - [ ] `wc -l ansible.cfg` — < 100 linhas
  - [ ] `ansible.cfg` não contém `/home/` (paths atualizados)
  - [ ] `ansible.cfg` ainda tem `inventory = hosts`
  - [ ] `ansible.cfg` ainda tem `vault_password_file`

  **QA Scenarios**:
  ```
  Scenario: ansible.cfg reduzido
    Tool: Bash
    Steps:
      1. wc -l ansible.cfg
      2. Assert output < 100
    Expected Result: Menos de 100 linhas
    Evidence: .sisyphus/evidence/task-14-cfg-size.txt

  Scenario: Paths atualizados
    Tool: Bash
    Steps:
      1. grep "/home/" ansible.cfg
    Expected Result: Nenhuma referência a /home/
    Evidence: .sisyphus/evidence/task-14-cfg-paths.txt
  ```

  **Commit**: YES (grupo T10-T15)

---

- [ ] 15. Adaptar cron setup para macOS

  **What to do**:
  - Adaptar `roles/base/tasks/system_setup/cron.yml` para macOS:
    - Remover task `service: name=cronie` (systemd, Linux-only)
    - No macOS, cron é built-in (launchd启动) mas pode precisar ser habilitado
    - Ajustar path do provision script: `/usr/local/bin/provision` (já correto)
    - Manter o cron job do velociraptor mas com paths macOS
    - Verificar se `cron_package` var é necessária no macOS
  - Adaptar cleanup at boot task para macOS paths

  **Must NOT do**:
  - Não converter para launchd (usuário escolheu manter cron)
  - Não mudar o agendamento (ansible_cron_hour/minute)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T10-T14 na Wave 3)
  - **Parallel Group**: Wave 3
  - **Blocks**: T20
  - **Blocked By**: T11

  **References**:
  - `roles/base/tasks/system_setup/cron.yml` — 40 linhas, cron setup com cronie service

  **Acceptance Criteria**:
  - [ ] `cron.yml` não referencia `cronie` ou systemd service
  - [ ] `cron.yml` mantém o cron job do provision
  - [ ] `cron.yml` usa paths `/Users/` ou paths não-hardcoded

  **QA Scenarios**:
  ```
  Scenario: Cron sem Linux dependencies
    Tool: Bash
    Steps:
      1. grep -n "cronie\|systemd\|/home/" roles/base/tasks/system_setup/cron.yml
    Expected Result: Nenhuma referência a cronie, systemd, ou /home/
    Evidence: .sisyphus/evidence/task-15-cron-macos.txt
  ```

  **Commit**: YES (grupo T10-T15)

---

- [ ] 16. Corrigir bootstrap.sh

  **What to do**:
  - Corrigir `bootstrap.sh`:
    - Remover referência a `install-darwin.sh` (linha 5: `caffeinate -i ./install-darwin.sh` — arquivo não existe)
    - Remover `sudo pacman` commands (Linux-only)
    - Remover `sed -i` em `/etc/pacman.conf` (Linux-only)
    - Manter a lógica de: instalar Homebrew, instalar pass, instalar ansible, rodar ansible-pull
    - Adaptar paths: `/home/` → `/Users/` se necessário
    - Remover `sudo touch /var/log/ansible.log; sudo chown $USER:$USER /var/log/ansible.log` ou adaptar para macOS
    - Verificar se o comando `ansible-pull` no final está correto para macOS
  - Garantir `bash -n` passa

  **Must NOT do**:
  - Não reescrever do zero — apenas corrigir

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T17-T19 na Wave 4)
  - **Parallel Group**: Wave 4
  - **Blocks**: T20
  - **Blocked By**: T2

  **References**:
  - `bootstrap.sh` — 86 linhas, script de bootstrap que instala ansible + roda ansible-pull

  **Acceptance Criteria**:
  - [ ] `bash -n bootstrap.sh` — exit 0 (syntax ok)
  - [ ] `bootstrap.sh` não referencia `install-darwin.sh`
  - [ ] `bootstrap.sh` não referencia `pacman`

  **QA Scenarios**:
  ```
  Scenario: bootstrap.sh syntax válido
    Tool: Bash
    Steps:
      1. bash -n bootstrap.sh; echo $?
    Expected Result: 0 (sem erros de syntax)
    Evidence: .sisyphus/evidence/task-16-bootstrap-syntax.txt

  Scenario: Sem referências Linux
    Tool: Bash
    Steps:
      1. grep -n "pacman\|install-darwin\|install-linux" bootstrap.sh
    Expected Result: Nenhuma referência
    Evidence: .sisyphus/evidence/task-16-bootstrap-no-linux.txt
  ```

  **Commit**: YES (grupo T16-T19)
  - Message: `refactor: update shell scripts for macOS`

---

- [ ] 17. Atualizar Brewfile syntax + revisão de pacotes

  **What to do**:
  - Atualizar syntax no `Brewfile`:
    - `cask "app"` → `brew install --cask "app"` OU usar syntax moderna: `cask "app"` (homebrew-bundle aceita ambos, mas syntax é `cask`)
    - NOTA: `brew cask` CLI command foi depreciado, MAS no Brewfile, a syntax `cask "app"` continua válida com `brew bundle`
    - Remover pacotes claramente obsoletos:
      - `brew "mps-youtube"` — projeto descontinuado
      - `brew "perl@5.18"` — versão antiga, provavelmente não necessária
      - `brew "mono"` — .NET Framework legado
      - `brew "mongodb"` — removido do Homebrew
      - `cask "beaker-browser"` — descontinuado
      - `cask "adium"` — descontinuado
      - `cask "mi"` — descontinuado
      - `cask "robo-3t"` — descontinuado (substituído por mongosh)
      - `cask "jeromelebel-mongohub"` — descontinuado
      - `cask "nosqlbooster-for-mongodb"` — possível problema de license
      - `cask "pibakery"` — descontinuado
      - `cask "seashore"` — descontinuado
      - `cask "little-snitch"` — agora `cask "little-snitch-4"` (verificar)
    - Remover `tap` entries que não são mais necessários
    - Remover pacotes duplicados: `brew "mitmproxy"` aparece 2x (linhas 278, 285)
  - Limpar comentários excessivos
  - Organizar por categoria (Shell, Languages, Servers, etc.)

  **Must NOT do**:
  - Não remover pacotes que o usuário pode ainda usar — apenas os claramente descontinuados
  - Não adicionar novos pacotes
  - Não questionar cada pacote um por um — focar nos obviamente obsoletos

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T16, T18-T19 na Wave 4)
  - **Parallel Group**: Wave 4
  - **Blocks**: T20
  - **Blocked By**: T2

  **References**:
  - `Brewfile` — 574 linhas, todos pacotes brew/cask
  - Homebrew docs: syntax `cask "app"` é válida no Brewfile com `brew bundle`

  **Acceptance Criteria**:
  - [ ] Pacotes obsoletos removidos (mps-youtube, adium, robo-3t, etc.)
  - [ ] Duplicatas removidas (mitmproxy aparece 2x)
  - [ ] `brew bundle check --file=Brewfile` não reporta errors de syntax
  - [ ] `wc -l Brewfile` — significativamente reduzido (< 400 linhas)

  **QA Scenarios**:
  ```
  Scenario: Brewfile sem pacotes descontinuados
    Tool: Bash
    Steps:
      1. grep -n "mps-youtube\|adium\|robo-3t\|pibakery\|seashore\|beaker-browser\|jeromelebel" Brewfile
    Expected Result: Nenhuma referência
    Evidence: .sisyphus/evidence/task-17-brewfile-cleanup.txt

  Scenario: Sem duplicatas
    Tool: Bash
    Steps:
      1. grep -c 'mitmproxy' Brewfile
    Expected Result: 1 (ou 0 se removido)
    Evidence: .sisyphus/evidence/task-17-no-dupes.txt

  Scenario: Tamanho reduzido
    Tool: Bash
    Steps:
      1. wc -l Brewfile
    Expected Result: < 400 linhas (de 574)
    Evidence: .sisyphus/evidence/task-17-brewfile-size.txt
  ```

  **Commit**: YES (grupo T16-T19)

---

- [ ] 18. Atualizar update.sh syntax brew

  **What to do**:
  - Corrigir `update.sh`:
    - Substituir `brew cask` CLI por `brew install --cask` (ou `brew upgrade --cask`):
      - Linha 37: `brew cask outdated` → `brew outdated --cask`
      - Linha 46: `brew cask upgrade` → `brew upgrade --cask`
    - Remover pacotes da lista de exclusão que são obsoletos (metasploit, etc.)
    - Verificar se demais comandos ainda são válidos no macOS Sonoma
    - Manter `osascript` notification no final (ainda funciona)
    - Remover `npx -q carbon-now-cli` se não for mais usado

  **Must NOT do**:
  - Não reescrever — apenas corrigir syntax depreciado
  - Não adicionar novas funcionalidades

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T16-T17, T19 na Wave 4)
  - **Parallel Group**: Wave 4
  - **Blocks**: T20
  - **Blocked By**: T2

  **References**:
  - `update.sh` — 106 linhas, script de atualização do sistema

  **Acceptance Criteria**:
  - [ ] `bash -n update.sh` — exit 0
  - [ ] `update.sh` não contém `brew cask` (depreciado)

  **QA Scenarios**:
  ```
  Scenario: update.sh syntax válido
    Tool: Bash
    Steps:
      1. bash -n update.sh; echo $?
    Expected Result: 0
    Evidence: .sisyphus/evidence/task-18-update-syntax.txt

  Scenario: Sem brew cask depreciado
    Tool: Bash
    Steps:
      1. grep -n "brew cask" update.sh
    Expected Result: Nenhuma referência
    Evidence: .sisyphus/evidence/task-18-no-brew-cask.txt
  ```

  **Commit**: YES (grupo T16-T19)

---

- [ ] 19. Limpar tweak-system-root.sh

  **What to do**:
  - Limpar `tweak-system-root.sh`:
    - Remover entradas de apps que não existem mais no macOS Sonoma:
      - `TextEdit.app` — ainda existe, manter
      - `iBooks.app` — renomeado para `Books.app`
      - `Chess.app` — não existe mais no Sonoma
      - `Mail.app` — ainda existe, verificar se usuário quer remover
      - `Messages.app` — ainda existe
      - `Maps.app` — ainda existe
    - Adicionar note: "WARNING: Este script remove apps nativas do macOS. Executar com cuidado."
    - Remover agents/daemons que não existem mais no Sonoma
    - Limpar código comentado excessivo
    - Manter a estrutura interativa (Execute/Restore/Quit)
    - Adicionar `set -euo pipefail`

  **Must NOT do**:
  - Não desabilitar serviços que possam quebrar o macOS
  - Não adicionar novos tweaks

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (com T16-T18 na Wave 4)
  - **Parallel Group**: Wave 4
  - **Blocks**: T20
  - **Blocked By**: T2

  **References**:
  - `tweak-system-root.sh` — 244 linhas, disable/restore macOS agents and daemons

  **Acceptance Criteria**:
  - [ ] `bash -n tweak-system-root.sh` — exit 0
  - [ ] Apps inexistentes removidos da lista de delete
  - [ ] Script ainda tem estrutura interativa E/R/Q

  **QA Scenarios**:
  ```
  Scenario: tweak script syntax válido
    Tool: Bash
    Steps:
      1. bash -n tweak-system-root.sh; echo $?
    Expected Result: 0
    Evidence: .sisyphus/evidence/task-19-tweak-syntax.txt

  Scenario: Apps inexistentes removidos
    Tool: Bash
    Steps:
      1. grep "iBooks.app" tweak-system-root.sh
    Expected Result: 0 (não referenciado, ou atualizado para Books.app)
    Evidence: .sisyphus/evidence/task-19-apps-cleanup.txt
  ```

  **Commit**: YES (grupo T16-T19)

---

- [ ] 20. Validação final — dry-run + relatório preliminar

  **What to do**:
  - Executar validações finais:
    1. `bash -n` em todos scripts shell na raiz (bootstrap.sh, update.sh, tweak-system-root.sh, run.sh)
    2. Verificar que `local.yml` tem syntax YAML válida
    3. `grep -r "/home/" roles/ local.yml hosts` — nenhuma referência a /home/ em código ativo
    4. `grep -rE "(apt|pacman|systemd|cronie)" roles/ --include="*.yml"` — sem referências Linux sem guard
    5. Verificar que `linux/` contém os arquivos esperados
    6. Verificar que arquivos mortos não existem mais na raiz
    7. Gerar métricas pós-refatoração (comparar com T3 baseline)
    8. Salvar tudo em `.sisyphus/evidence/task-20-validation.md`

  **Must NOT do**:
  - Não executar `ansible-playbook` sem `--check` (dry-run)
  - Não modificar nenhum arquivo — apenas validar

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (depende de T3, T10-T19)
  - **Parallel Group**: Wave 4 (último)
  - **Blocks**: F1, F2
  - **Blocked By**: T3, T10-T19

  **References**:
  - `.sisyphus/evidence/task-3-baseline.txt` — Métricas de baseline

  **Acceptance Criteria**:
  - [ ] Todos scripts passam `bash -n`
  - [ ] `local.yml` é YAML válido
  - [ ] Zero referências a `/home/` em código ativo
  - [ ] Zero referências Linux sem guard
  - [ ] `linux/` contém os arquivos movidos
  - [ ] Documento de validação gerado

  **QA Scenarios**:
  ```
  Scenario: Todos scripts passam syntax check
    Tool: Bash
    Steps:
      1. for f in bootstrap.sh update.sh tweak-system-root.sh run.sh; do bash -n "$f" || echo "FAIL: $f"; done
    Expected Result: Nenhum "FAIL" output
    Evidence: .sisyphus/evidence/task-20-scripts-validation.txt

  Scenario: Zero referências Linux
    Tool: Bash
    Steps:
      1. grep -rn "/home/" roles/ local.yml hosts 2>/dev/null | head -5
      2. grep -rnE "(apt|pacman|systemd|cronie)" roles/base/tasks/ roles/workstation/tasks/ --include="*.yml" | grep -v "when:" | head -5
    Expected Result: Nenhuma referência sem guard
    Evidence: .sisyphus/evidence/task-20-linux-refs.txt

  Scenario: Métricas pós-refatoração
    Tool: Bash
    Steps:
      1. echo "Root files: $(ls -1 | wc -l)"
      2. echo "Linux dir files: $(find linux/ -type f 2>/dev/null | wc -l)"
      3. echo "ansible.cfg lines: $(wc -l < ansible.cfg)"
      4. echo "Brewfile lines: $(wc -l < Brewfile)"
    Expected Result: Valores numéricos que mostram redução
    Evidence: .sisyphus/evidence/task-20-post-metrics.txt
  ```

  **Commit**: NO

---

## Final Verification Wave

> 2 reviews rodam em PARALELO. Apresentar resultados consolidados ao usuário.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Ler o plano end-to-end. Para cada "Must Have": verificar implementação (ler arquivo, grep, executar comando). Para cada "Must NOT Have": buscar no código por padrões proibidos. Verificar evidence files em `.sisyphus/evidence/`. Comparar deliverables contra plano.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Relatório de Redução Final** — `unspecified-high`
  Comparar estado antes (T3) com estado depois. Contar: arquivos na raiz antes/depois, linhas totais antes/depois, roles antes/depois, playbooks antes/depois. Gerar `REFACTOR_REPORT.md` com métricas concretas.
  Output: `Arquivos [N→N] | Linhas [N→N] | Roles [N→N] | Redução [%] | VERDICT`

---

## Commit Strategy

- **T1**: `chore: create pre-macos-refactor backup tag` — git tag only
- **T4-T9**: `refactor: move Linux-specific files to linux/ directory` — git mv files
- **T10-T15**: `refactor: adapt Ansible roles and config for macOS` — yml, j2 files
- **T16-T19**: `refactor: update shell scripts for macOS` — sh files
- **T20**: `docs: add refactor report` — REFACTOR_REPORT.md
- **F2**: `docs: final reduction report` — REFACTOR_REPORT.md update

---

## Success Criteria

### Comandos de Verificação
```bash
# Sem erros fatais no dry-run
ansible-playbook --check --diff local.yml  # Expected: no fatal errors

# Nenhuma referência a /home/ em playbooks ativos
grep -r "/home/" roles/ local.yml 2>/dev/null  # Expected: no output

# Nenhuma referência a apt/pacman/systemd
grep -rE "(apt|pacman|systemd|cronie)" roles/base/tasks/ roles/workstation/tasks/ 2>/dev/null  # Expected: no output

# Linux dir contém os arquivos movidos
ls linux/packages.txt linux/packages_aur.txt linux/modules/ linux/collections/ 2>/dev/null  # Expected: files exist

# Brewfile syntax válido
brew bundle check --file=Brewfile  # Expected: no errors

# Scripts com syntax válida
bash -n bootstrap.sh && bash -n update.sh && bash -n provision.sh  # Expected: exit 0

# Root limpo — sem arquivos Linux-only
ls site.yml vnc.yml 2>/dev/null  # Expected: file not found
```

### Checklist Final
- [ ] Todos "Must Have" presentes
- [ ] Todos "Must NOT Have" ausentes
- [ ] `ansible-playbook --check --diff local.yml` sem erros
- [ ] Relatório de redução gerado com métricas concretas
