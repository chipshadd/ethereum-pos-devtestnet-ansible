#/usr/bin/env bash
ansible-playbook \
    --private-key ~/.ssh/id_eth_testnet \
    -u ubuntu \
    -i hosts \
    "$@" \
    multi.yml