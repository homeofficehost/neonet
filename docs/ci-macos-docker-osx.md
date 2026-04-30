# CI macOS com Docker-OSX

## Status

O workflow de CI anterior foi desativado pois testava playbooks macOS em runners Ubuntu,
resultando em falsos positivos (o playbook falha silenciosamente em tasks macOS-specific).

## Opcao futura: Docker-OSX

O projeto [sickcodes/Docker-OSX](https://github.com/sickcodes/Docker-OSX) permite rodar
macOS virtualizado dentro de Docker com KVM.

### Como funcionaria:

1. GitHub Actions runner (Ubuntu) com KVM habilitado
2. Container Docker-OSX rodando macOS Ventura/Sonoma
3. Dentro do container, rodar o `bootstrap.sh` ou `ansible-pull`

### Exemplo de workflow (NAO TESTADO):

```yaml
name: Test macOS via Docker-OSX
on: [push, pull_request]
jobs:
  docker-osx-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run macOS in Docker
        run: |
          docker run -d \
            --device /dev/kvm \
            -p 50922:10022 \
            -v "${PWD}:/repo" \
            -e SHORTNAME=sonoma \
            sickcodes/docker-osx:latest
      - name: Wait for SSH
        run: sleep 300
      - name: Run bootstrap
        run: |
          sshpass -p alpine ssh -o StrictHostKeyChecking=no \
            -p 50922 user@localhost \
            "cd /repo && ./bootstrap.sh"
```

### Problemas conhecidos:

- Tempo de boot do macOS VM: 5-10 minutos
- Precisa de `device /dev/kvm` (disponivel em runners GitHub standard)
- Apple ID pode bloquear logins de VMs
- Performance lenta para testes completos de Ansible

### Alternativa recomendada:

Para este projeto (uso pessoal, single-machine), CI local via pre-commit hook:

```bash
# .git/hooks/pre-commit
ansible-playbook --syntax-check -i hosts local.yml
```

Ou usar `ansible-lint` no CI (cross-platform, valida sintaxe sem executar).
