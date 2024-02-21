#/usr/bin/env bash
ansible-playbook \
    --private-key ~/.ssh/id_eth_testnet \
    -e @single_target_vars.yml \
    -u ubuntu \
    -i single_host \
    "$@" \
    single.yml