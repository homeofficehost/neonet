=== VALIDAÇÃO FINAL ===

## Verificação de Scripts
✓ bootstrap.sh: syntax OK
✓ update.sh: syntax OK
✓ tweak-system-root.sh: syntax OK
✓ run.sh: syntax OK

## Verificação de Referências Linux

### Referências a /home/ em código ativo:
/home/tg/dev/neonet/roles/base/defaults/main.yml:3:repo_dir: /home/{{ username }}/.bare-dotfiles/
/home/tg/dev/neonet/roles/base/defaults/main.yml:4:work_dir: /home/{{ username }}/
/home/tg/dev/neonet/roles/base/tasks/users/user.yml:39:    - { dir: "/home/{{ username }}/.ssh" }
/home/tg/dev/neonet/roles/base/tasks/users/user.yml:212:    dest: "/home/{{ username }}/.config/git/"
/home/tg/dev/neonet/roles/base/tasks/users/user.yml:221:    dest: "/home/{{ username }}/.config/pass-git-helper/"

### Referências a pacman/apt/systemd:
/home/tg/dev/neonet/roles/base/tasks/software/packages_utilities.yml:54:  pacman:
/home/tg/dev/neonet/roles/base/tasks/software/repositories.yml:4:      dest: /etc/pacman.conf
/home/tg/dev/neonet/roles/base/tasks/software/repositories.yml:9:- name: system setup | enable pacman parallel downloads for faster downloads
/home/tg/dev/neonet/roles/base/tasks/software/repositories.yml:12:      dest: /etc/pacman.conf
/home/tg/dev/neonet/roles/base/tasks/software/repositories.yml:21:    dest: /etc/apt/sources.list
