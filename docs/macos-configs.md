# macOS Configs — Referência Rápida

> Fonte: `roles/workstation/tasks/system_setup/macos_defaults.yml`
> Aplicar mudança manual: `defaults write NSGlobalDomain <KEY> -<TYPE> <VALUE> && killall cfprefsd`

---

## Teclado

| Setting | Domain | Key | Tipo | Valor atual | Escala |
|---|---|---|---|---|---|
| Delay antes de repetir | NSGlobalDomain | `InitialKeyRepeat` | int | `10` | 10 (rápido) → 120 (lento) |
| Velocidade de repetição | NSGlobalDomain | `KeyRepeat` | int | `2` | 1 (rápido) → 6 (lento) |
| Press-and-hold (acentos) | NSGlobalDomain | `ApplePressAndHoldEnabled` | bool | `false` | false = repete; true = mostra acentos |
| Auto-correct | NSGlobalDomain | `NSAutomaticSpellingCorrectionEnabled` | bool | `false` | |
| Smart quotes | NSGlobalDomain | `NSAutomaticQuoteSubstitutionEnabled` | bool | `false` | |
| Smart dashes | NSGlobalDomain | `NSAutomaticDashSubstitutionEnabled` | bool | `false` | |
| Full keyboard access (Tab em todos os controles) | NSGlobalDomain | `AppleKeyboardUIMode` | int | `3` | 0=off, 2=text, 3=all |

## Trackpad

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| Haptic feedback (click) | com.apple.AppleMultitouchTrackpad | `FirstClickThreshold` | int | `0` (light) |
| Haptic feedback (strength) | com.apple.AppleMultitouchTrackpad | `ActuationStrength` | int | `0` (light) |
| Tap to click | NSGlobalDomain | `com.apple.mouse.tapBehavior` | int | `1` |
| Right-click (two finger) | com.apple.AppleMultitouchTrackpad | `TrackpadRightClick` | bool | `true` |
| Three finger drag | com.apple.AppleMultitouchTrackpad | `TrackpadThreeFingerDrag` | bool | `true` |
| Tap-and-a-half drag | com.apple.AppleMultitouchTrackpad | `Dragging` | int | `1` |
| Natural scrolling | NSGlobalDomain | `com.apple.swipescrolldirection` | bool | `true` |

## Dock & Janelas

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| Ícone tamanho | com.apple.dock | `tilesize` | int | `36` |
| Minimizar efeito | com.apple.dock | `mineffect` | string | `scale` |
| Minimizar no ícone do app | com.apple.dock | `minimize-to-application` | bool | `true` |
| Auto-hide delay | com.apple.dock | `autohide-delay` | float | `0` |
| Auto-hide animação | com.apple.dock | `autohide-time-modifier` | float | `0` |
| Mission Control animação | com.apple.dock | `expose-animation-duration` | float | `0` |
| Spaces switching animação | com.apple.dock | `spaces-animation-delay` | float | `0` |
| Reduce Motion (fullscreen/Spaces) | com.apple.Accessibility | `ReduceMotionEnabled` | int | `1` |
| Launch animação | com.apple.dock | `launchanim` | bool | `false` |
| Dock transparente p/ apps hidden | com.apple.dock | `showhidden` | bool | `true` |
| Resize speed (Cocoa) | NSGlobalDomain | `NSWindowResizeTime` | float | `0.001` |
| Window open/close animação | NSGlobalDomain | `NSAutomaticWindowAnimationsEnabled` | bool | `false` |
| Restore windows no login | NSGlobalDomain | `NSQuitAlwaysKeepsWindows` | bool | `false` |
| Quick Look animação | NSGlobalDomain | `QLPanelAnimationDuration` | float | `0` |

## Hot Corners

| Canto | Ação | Valor |
|---|---|---|
| Top-left | Application Windows | `2` |
| Top-right | Application Windows | `2` |
| Bottom-left | Desktop | `6` |
| Bottom-right | Desktop | `6` |

> Modifiers: todos `0` (sem modifier). Domínio: `com.apple.dock`, keys: `wvous-{tl,tr,bl,br}-{corner,modifier}`

## Finder

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| Extensões visíveis | NSGlobalDomain | `AppleShowAllExtensions` | bool | `true` |
| Status bar | com.apple.finder | `ShowStatusBar` | bool | `true` |
| Path no título | com.apple.finder | `_FXShowPosixPathInTitle` | bool | `true` |
| Folders on top | com.apple.finder | `_FXSortFoldersFirst` | bool | `true` |
| Column view default | com.apple.finder | `FXPreferredViewStyle` | string | `clmv` |
| Search scope = pasta atual | com.apple.finder | `FXDefaultSearchScope` | string | `SCcf` |
| Novo Finder abre Desktop | com.apple.finder | `NewWindowTarget` | string | `PfDe` |
| Snap-to-grid icons | PlistBuddy | `*:IconViewSettings:arrangeBy` | — | `grid` |
| Icon size | PlistBuddy | `*:IconViewSettings:iconSize` | — | `64` |
| Animações desativadas | com.apple.finder | `DisableAllAnimations` | bool | `true` |
| Aviso mudar extensão | com.apple.finder | `FXEnableExtensionChangeWarning` | bool | `false` |
| Aviso lixeira | com.apple.finder | `WarnOnEmptyTrash` | bool | `false` |
| Cmd+Q fecha Finder | com.apple.finder | `QuitMenuItem` | bool | `true` |
| Text selection no Quick Look | com.apple.finder | `QLEnableTextSelection` | bool | `true` |
| .DS_Store em rede | com.apple.desktopservices | `DSDontWriteNetworkStores` | bool | `true` |
| Spring loading | NSGlobalDomain | `com.apple.springing.enabled` | bool | `true` |
| Spring loading delay | NSGlobalDomain | `com.apple.springing.delay` | float | `0.1` |
| Library visível | — | `chflags nohidden ~/Library` | — | — |

## UI Geral

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| Save panel expandido | NSGlobalDomain | `NSNavPanelExpandedStateForSaveMode` | bool | `true` |
| Print panel expandido | NSGlobalDomain | `PMPrintingExpandedStateForPrint` | bool | `true` |
| Save local (não iCloud) | NSGlobalDomain | `NSDocumentSaveNewDocumentsToCloud` | bool | `false` |
| Font smoothing | NSGlobalDomain | `AppleFontSmoothing` | int | `2` |
| Auto-terminate apps | NSGlobalDomain | `NSDisableAutomaticTermination` | bool | `true` |
| Quit printer app | com.apple.print.PrintingPrefs | `Quit When Finished` | bool | `true` |

## Screenshot

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| Local | com.apple.screencapture | `location` | string | `~/Downloads` |
| Formato | com.apple.screencapture | `type` | string | `png` |
| Shadow | com.apple.screencapture | `disable-shadow` | bool | `true` |

## Terminal & Dev

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| UTF-8 encoding | com.apple.terminal | `StringEncodings` | array | `[4]` |
| WebKit dev extras | NSGlobalDomain | `WebKitDeveloperExtras` | bool | `true` |
| File quarantine | com.apple.LaunchServices | `LSQuarantine` | bool | `false` |

## Activity Monitor

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| Open main window | com.apple.ActivityMonitor | `OpenMainWindow` | bool | `true` |
| Show all processes | com.apple.ActivityMonitor | `ShowCategory` | int | `0` |

## App Store

| Setting | Domain | Key | Tipo | Valor |
|---|---|---|---|---|
| In-app rating popup | com.apple.appstore | `InAppReviewEnabled` | int | `0` |
| Hide serial number | /Library/Preferences/com.apple.SystemProfiler | `Hide Serial Number` | bool | `true` |

---

## Editores/Shell instalados

| Tool | Tipo | Nota |
|---|---|---|
| micro | brew | Editor terminal simples |
| vim / neovim | brew | |
| kitty / iterm2 | cask | Terminais |
| oh-my-zsh | git clone | Framework zsh |
| starship | brew | Prompt customizável |
| z-zsh | git clone | Directory jumping |

## Linguagens & Runtimes

| Tool | Manager |
|---|---|
| rust | brew |
| go | brew |
| python3 / pyenv / uv / pipx | brew |
| node / nvm / npm / yarn | brew |
| ruby / rbenv | brew |
| php / composer | brew |

## Bancos

| Tool | Tipo |
|---|---|
| postgresql | brew |
| mariadb | brew |
| redis | brew |

## Git Tools

| Tool | Tipo |
|---|---|
| git / gh / lazygit | brew |
| git-flow / git-lfs / git-extras | brew |
| fork | cask |

---

## Reiniciar serviços após alteração manual

```bash
killall cfprefsd      # prefs cache
killall Dock           # Dock + hot corners
killall Finder         # Finder prefs
killall SystemUIServer # UI prefs
```
