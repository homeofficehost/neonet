# Push-to-Talk (PTT)

Sistema push-to-talk exclusivo para o Discord usando microfone virtual BlackHole.

## Como funciona

Quando você **segura** a tecla `Right Option` (⌥ direito), o microfone é **mutado** no Discord. Quando você **solta**, o Discord volta a ouvir.

O app alvo (ex: Handy) continua recebendo o microfone real normalmente, independente da tecla.

## Componentes

| Componente | Arquivo | Função |
|---|---|---|
| `audiobridge` | `/usr/local/bin/audiobridge` | Daemon Go que faz bridge microfone → BlackHole |
| LaunchAgent | `~/Library/LaunchAgents/com.user.audiobridge.plist` | Mantém o daemon rodando |
| Karabiner | `~/.config/karabiner/karabiner.json` | Captura Right Option e envia sinais |
| BlackHole 2ch | Dispositivo virtual | Canal controlado pelo daemon |

## Setup manual (primeira vez)

### 1. Configure o Discord

Abra **Discord** → Configurações → Voz e Vídeo → Dispositivo de Entrada → Selecione **"BlackHole 2ch"**

### 2. Configure o app alvo (ex: Handy)

Configure o app para usar o **microfone real** (fifine/Monoise). Não use o BlackHole.

### 3. Teste

```bash
# Verifique se o daemon está rodando
pgrep -x audiobridge

# Veja os logs em tempo real
tail -f /tmp/audiobridge.out
```

Segure `Right Option` → log deve mostrar "closing bridge" (Discord mudo)
Solte `Right Option` → log deve mostrar "opening bridge" (Discord ouvindo)

## Reinstalação via Ansible

```bash
cd ~/pro/neonet
ansible-playbook -i hosts local.yml --tags pushtotalk
```

## Arquitetura

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  Microfone real │────▶│  audiobridge │────▶│ BlackHole   │
│  (fifine/Monoise)│     │   daemon     │     │   2ch       │
└─────────────────┘     └──────────────┘     └──────┬──────┘
                                                    │
                                                    ▼
                                              ┌──────────┐
                                              │ Discord  │
                                              └──────────┘
```

- Daemon roda o tempo todo via `launchd`
- Karabiner captura `Right Option` e envia `SIGUSR1`/`SIGUSR2`
- Bridge aberta = Discord ouve. Bridge fechada = Discord mudo.

## Dependências

- BlackHole 2ch (`brew install blackhole-2ch`)
- Karabiner-Elements (`brew install karabiner-elements`)
- Go (para build do daemon)
- PortAudio (`brew install portaudio`)

## Troubleshooting

### Discord não aparece no BlackHole

Verifique se o BlackHole está selecionado como input no Discord.

### Daemon não está rodando

```bash
launchctl list | grep audiobridge
# ou
pgrep -x audiobridge
```

Se não estiver:
```bash
launchctl load -w ~/Library/LaunchAgents/com.user.audiobridge.plist
```

### Permissão de microfone

O macOS pede permissão na primeira execução. Vá em:
**Preferências do Sistema** → **Privacidade e Segurança** → **Microfone** → Adicione `audiobridge`.

### Karabiner não está aplicando a regra

Reinicie o Karabiner-Elements:
```bash
killall karabiner-elements 2>/dev/null; open -a "Karabiner-Elements"
```

### Rebuild manual do daemon

```bash
cd ~/pro/neonet/roles/pushtotalk/files/src
unset GOROOT
make build
make install
launchctl unload ~/Library/LaunchAgents/com.user.audiobridge.plist
launchctl load -w ~/Library/LaunchAgents/com.user.audiobridge.plist
```
