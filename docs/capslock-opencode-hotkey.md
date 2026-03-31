# Caps Lock → opencode (quake-style toggle)

Caps Lock remapeado para abrir/esconder kitty rodando opencode, globalmente.

## Fluxo

| Estado | Ação |
|---|---|
| Kitty não rodando | Abre kitty + executa `opencode` |
| Kitty rodando, sem foco | Traz para frente |
| Kitty em foco | Esconde |

Caps Lock segurado continua funcionando como **Left Control**.

## Mecanismo

```
Caps Lock (alone, ≤250ms) → F18 → Hammerspoon → toggle kitty+opencode
Caps Lock (held)          → Left Control (normal modifier)
```

- **Karabiner-Elements** faz o remapeamento físico (complex modification `caps_lock_to_f18.json`)
- **Hammerspoon** captura F18 e gerencia o toggle (`init.lua`)

## Arquivos

```
roles/workstation/files/karabiner/caps_lock_to_f18.json   # regra karabiner
roles/workstation/files/hammerspoon/init.lua               # config hammerspoon
roles/workstation/tasks/system_setup/hammerspoon.yml        # ansible deployment
```

## Aplicar

```bash
ansible-pull --url https://github.com/homeofficehost/neonet \
  --limit $(hostname -s).local --tags hammerspoon,karabiner
```

A regra do Karabiner é auto-habilitada no profile ativo via Ansible — sem intervenção manual.
