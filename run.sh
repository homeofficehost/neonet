#!/bin/bash
set -o pipefail
ansible-playbook -i localhost, local.yml "$@" 2>&1 | tee -a "$HOME/ansible_provision.log"
exit "${PIPESTATUS[0]}"
