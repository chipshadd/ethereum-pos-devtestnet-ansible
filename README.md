# Ethereum2 PoS development test network with Ansible

## Prerequisites
- Ubuntu is assumed to be used on any machine these playbooks target (as well as an `ubuntu` user with `sudo` privileges).
### Multi-server network
Add all server IPs to the `[nodes]` group in your inventory.
Optionally, add or designate a server to be the load balancer in the `[lb]` group

#### Notes
- Playbook will configure 1 ethereum node, 1 beacon node per server, and 1 validator client per host
- First node in the inventory will serve as the boot node for ( both execution and consensus layer) all other nodes
### Single server network (or localhost)
Update your inventory to ensure only 1 IP (`localhost` for local deployment) exists in the `[nodes]` group and pass in the following extra variables:
- `"target=single"`
- `"nodecount=<int>"` # the number specified here is how many eth/beacon/validator nodes will be provisioned on the same 1 server

See example in the `run_single.sh` script.

## Running the play
Once your hosts file is properly configured for your use case, run the following command:
`ansible-playbook [-e @optional_extra_vars.yml] main.yml`

## Variables
Variables and their default values can be found at `roles/default_vars.yml`.  Override any of the following through the `--extra-vars` flag at runtime:
(Preferably define the specific variables you want to change in a separate file and call it with `-e @override_vars.yml`)
### General variables

- `init: boolean` - Default: `true`
Wipes out everything and starts fresh, Disable this if running plays against already established networks
- `target: string` - Default: `multi` 
Acceptable values: `multi`, `single`
Determines if the testnet will span muiltple hosts or run on a single host.  This will impact port numbers and directory names to support multiple execution and consensus clients running on the same host.
- `nodecount: int` - Only override this value when running with `target: single`. Determines how many execution/consensus clients to run on a single host network.
- `geth_version_commit: string` - Default: `1.13.11-8f7eb9cc`
 Geth client's semantic version followed by the commit hash. This variable is used to pull down pre-built geth binaries from https://geth.ethereum.org/downloads
- `lighthouse_version: string` - Default: `v4.6.0`
Lighthouse semantic version.  Used to pull down the lighthouse pre-built binary from https://github.com/sigp/lighthouse/releases 
If the lighthouse version changes, you may need to re-compile the `lcli` tool and replace it in - `roles/bootstrap/files/lcli` (recompile steps can be found `build_lcli.txt`)
- `basedir: file_path ` -Default: `/home/ubuntu/.lighthouse`
 Base directory for everything
- `datadir: file_path` - Default: `/home/ubuntu/.lighthouse/testnet`
Directory for various nodes and configs
- `testnetdir: file_path` - Default: `/home/ubuntu/.lighthouse/eth2`
eth2 network config
- `number_of_wallets: int` - Default: `2`
Number of wallets to provision in the genesis block
- `wallet_password: string` - Default: `1234`
Password for the genesis wallets 
- `starting_balance: int` - Default: `1000`
 Starting balance of each genesis wallet
### Network related variables
- `difficulty: hexidecimal` -  Default: `0x01`
Difficulty of the network (should be `0x01` for an eth2 post-merge test network)
- `deposit_contract_address: eth_address` - Default: `0x4242424242424242424242424242424242424242`
Arbitrary address to house the staking deposit smart contract 
- `genesis_fork_version: hexidecimal` - Default: `0x42424242`
Arbitrary fork version to potentially differentiate genesis block from other test networks (if discoverable). Minimum of 8 hex digits 
- `genesis_delay: int` - Default: `180`
 How long to delay genesis block creation.  Increase this value if it taking ansible long to stand up the network 
- `network_id: int` -  Default: `4242420`
 Arbitrary number to identify this network.  In case the network is spread across a public network, verify here that your network ID is not used: https://chainlist.org/?testnets=true 
 (Keep the value under `65535` as it is also used for node discovery over TCP/UDP)
- `spec_preset: string` - Default: `mainnet`
Accetpable values: `mainnet`|`minimal`|`gnosis`. Preset configs to apply to this test network 
- `seconds_per_slot: int` - Default: `3` 
Eth2 slot time
- `seconds_per_eth1_block: int` - Default: `3`
 Eth1 block time
- `proposer_score_boost: int` - Default: `40`
 Percentage boost to apply to proposer score
- `validator_count: int` - Default: `80`
- `genesis_validator_count: int` - Default: `80`

### Hard fork variables
Add/remove past/future hard forks as needed
These values are used as multipliers to determine and populate the hard fork epoch times. 
Formula is as follows: 
eg. (current_epoch + (`capella_fork_epoch` * slots_per_epoch * `seconds_per_slot`))
(`slots_per_epoch` is determined base on the `spec_preset` defined)
 - `altair_fork_epoch: int`  - default: `0`
 -  `bellatrix_fork_epoch: int` - default: `0`
 - `capella_fork_epoch: 1` - default: `1`
 - `deneb_fork_epoch: 2` - default: `2`
 - `ttd: int` - Default: `0`
 Set to non-zero for a pre-merge (eth1 PoW) network
### Geth related settings
```
geth: 
  init:
   extra_flags: list(string)
  bootnode:
    port: int
    extra_flags: list(string)
  node:
    port: int
    syncmode: string
    http:
      port: int
    api: string
    authrpc:
      port: int
    extra_flags: list(string)
```
- `geth:`
    - `init:`
        - `extra_flags: list(string)` - Default: None
        Additional command line arguments to pass to the `geth init` command
    - `bootnode:`
        - `port: int` - Default: `30301`
        The port in which geth nodes should discover the bootnode
    -  `extra_flags: list(string)` - Default: None
        Additional command line arguments to pass to the `boot_node` binary
    - `node:`
        - `port: int` - Default: `30303`
        The geth node's p2p port
        - `syncmode: string` - Default: `full`
        Acceptable values: `snap`|`full`. Blockchain sync mode
        - `http:`
            - `port: int` - Default: `8545`
            HTTP API port
        - `api: string` - Default: `"engine,eth,web3,net,debug"`
        Acceptible values: `admin`|`engine`|`eth`|`web3`|`net`|`debug`|`txpool`
        Comma separated string of the one or more of the above values
        - `authrpc:`
            - `port: int` - Default: `8551`
            Port for consensus layer to authenticate to
        - `extra_flags: string(list)` - 
        Default: 
        ```
        - --http
        - --http.corsdomain '*'
        ```
        Additional command line arguments to pass to the `geth` binary

### Lighthouse related settings
```
lighthouse:
  beacon_node:
    port: int
    enr_tcp_port: int
    enr_udp_port: int
    enr_quic_port: int
    quic_port: int
    http_port: int
    extra_flags: list(string)
  validator:
    http_port: int
    extra_flags: list(string)
  bootnode:
    port: int
    extra_flags: list(string)
```
- `lighthouse:`
    - `beacon_node:`
        - `port: int`- Default: `9001`
        Port beacon nodes listens on for other nodes
        - `enr_tcp_port: int` - Default: `9001`
        - `enr_udp_port: int` - Default: `9001`
        - `enr_quic_port: int` - Default: `9101`
        - `quic_port: int` - Default: `9101`
        - `http_port: int` - Default: `5052`
        Light house HTTP API port
        - `extra_flags: list(string)`
        Default:
        ```
        - --http
        - --subscribe-all-subnets
        - --enable-private-discovery
        - --disable-peer-scoring
        - --staking
        - --disable-packet-filter
        - --http-allow-sync-stalled
        ```
        Additional flags to pass to the `lighthouse bn` command
    -  `validator:`
        - `http_port: int` - Default: `5062`
        Validator API port
        - `extra_flags: list(string)`
        Default:
        ```
        - --http
        - --init-slashing-protection
        ```
        Additional flags to pass to the `lighthouse vc` command
    - `bootnode:`
        - `port: int` - Default: `4242`
        Port for beacon nodes to discover the bootnode
        - `extra_flags: list(string)`
        Default:
        ```
        - --disable-packet-filter
        ```
        Additional flags to pass to the `lcli boot_node` command

### Import wallet addresses to prefund
`import_wallets: [ eth_address ]` - List of eth addresses to import into the genesis block 

## Management script
There is a management script to manage and query the status of all the components.  It will be placed at `{{ basedir }}`
### Usage:
- `./manage.sh status [component]` - Query the status of all the components 
Acceptable values: `validators`|`beacon-node`|`lh-bootnode`|`geth-node`|`geth-bootnode`
Not passing in an argument to `status` will return the status of everything.
Example output:
```
validators:
  | State: Up (6223)
  | /usr/local/bin/lighthouse vc --http --init-slashing-protection --datadir /home/ubuntu/.lighthouse/testnet/beacon --testnet-dir /home/ubuntu/.lighthouse/eth2 --beacon-nodes http://localhost:5052 --http-port 5062 --suggested-fee-recipient 0x528b0029240f4AB222aeD5C04a55a5660871134e

beacon-node:
  | State: Up (6200)
  | /usr/local/bin/lighthouse bn --http --subscribe-all-subnets --enable-private-discovery --disable-peer-scoring --staking --disable-packet-filter --http-allow-sync-stalled --datadir /home/ubuntu/.lighthouse/testnet/beacon --testnet-dir /home/ubuntu/.lighthouse/eth2 --enr-address 172.31.39.162 --enr-udp-port 9001 --enr-tcp-port 9001 --enr-quic-port 9101 --port 9001 --quic-port 9101 --http-port 5052 --target-peers 1 --execution-endpoint http://localhost:8551 --boot-nodes -My4QHA3jPFA0E8vrA9fI4Qv5VtxVwK5U2DU5VppDRNh9kmoYdg9sxtHY4-frx8R_9EhlH1hgG6KKHLfclRlzjtnsH4Bh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCq8mMKQkJCQv__________gmlkgnY0gmlwhKwfJ6KEcXVpY4IjKYlzZWNwMjU2azGhAp5trZDTd6MwTvZ15GrmD9c13kATZ1jHZ2FoAyZXWc4jiHN5bmNuZXRzAIN0Y3CCIyiEdGNwNoIQkoN1ZHCCEJI --execution-jwt /home/ubuntu/.lighthouse/testnet/geth-node/geth/jwtsecret

lh-bootnode:
  | State: Up (5978)
  | /usr/local/bin/lighthouse boot_node --testnet-dir /home/ubuntu/.lighthouse/eth2 --port 4242 --listen-address 0.0.0.0 --network-dir /home/ubuntu/.lighthouse/testnet/bootnode

geth-node:
  | State: Up (6000)
  | /usr/local/bin/geth --http --http.corsdomain * --datadir /home/ubuntu/.lighthouse/testnet/geth-node --http.api engine,eth,web3,net,debug --networkid 42420 --syncmode full --bootnodes enode://d58f40ca299f05cb96f001c2dfa88640808eed6f2c8856b426895b837275d9088e9130ffb6f957510e5c7f5a3d5aab90f31fdca3483415cd3e687682a975b45f@172.31.39.162:30301 --port 30303 --http.port 8545 --authrpc.port 8551

geth-bootnode:
  | State: Up (5989)
  | /usr/local/bin/bootnode -verbosity 5 -nodekey /home/ubuntu/.lighthouse/testnet/bootnode.key
```

- `/manage.sh start|stop [component]` - Start/stop the specified component.
Acceptable values for `[component]`: `validators`|`beacon-node`|`lh-bootnode`|`geth-node`|`geth-bootnode`
Not passing in a `[component]` to `start` or `stop` will start/stop everything

### Notes
- Logs for each component can be found in the `{{ datadir }}/logs/` directory.
- PIDs for each component is store in the `{{ datadir }}` directory.

### Loadbalancer
An nginx load balancer is also provisioned (on the single host or a designated loadbalancer node) that will expose the following endpoints and loadbalance traffic to the respective components and ports:
(Default port:)

- `/geth` 
Distributes API calls to the HTTP APIs of the geth nodes
Example call:
```
curl http://localhost:8080/geth/ -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":2}' -H "Content-Type: application/json"
{"jsonrpc":"2.0","id":2,"result":{"baseFeePerGas":"0x3b9aca00","difficulty":"0x1","extraData":"0x","gasLimit":"0x400000","gasUsed":"0x0","hash":"0xe437fa866283dc6136cd743ebccf7e7fee6dcc236816d44e94597a17ff2a5888","logsBloom":"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000","miner":"0x0000000000000000000000000000000000000000","mixHash":"0x0000000000000000000000000000000000000000000000000000000000000000","nonce":"0x0000000000001234","number":"0x0","parentHash":"0x0000000000000000000000000000000000000000000000000000000000000000","receiptsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421","sha3Uncles":"0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347","size":"0x201","stateRoot":"0x2a8d752b2a5dd1f5f2549589883f11e4c8650e66ee9f82dcd68ed699199e506a","timestamp":"0x65d5cee6","totalDifficulty":"0x1","transactions":[],"transactionsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421","uncles":[]}}
```
- `/bn` 
Distributes API calls to the HTTP APIs of the beacon nodes
Example call:
```
curl http://localhost:8080/bn/eth/v1/beacon/genesis
{"data":{"genesis_time":"1708510627","genesis_validators_root":"0x740cb032a0da660447055fdb161b5e285f36dbc4b1cea2b49a15e3d6196aa6ed","genesis_fork_version":"0x42424242"}}
```
Included in the BeaconNode's API is ethereums standard beacon APIs, which is accessible via `/bn/lighthouse/`
Example call:
```
curl http://localhost:8080/bn/lighthouse/health
{"data":{"sys_virt_mem_total":2051227648,"sys_virt_mem_available":1614770176,"sys_virt_mem_used":258822144,"sys_virt_mem_free":688689152,"sys_virt_mem_percent":21.277866,"sys_virt_mem_cached":1052704768,"sys_virt_mem_buffers":51011584,"sys_loadavg_1":0.03,"sys_loadavg_5":0.02,"sys_loadavg_15":0.0,"cpu_cores":1,"cpu_threads":1,"system_seconds_total":55,"user_seconds_total":257,"iowait_seconds_total":11,"idle_seconds_total":21608,"cpu_time_total":21935,"disk_node_bytes_total":8132173824,"disk_node_bytes_free":5691244544,"disk_node_reads_total":13229,"disk_node_writes_total":68924,"network_node_bytes_total_received":1247621718,"network_node_bytes_total_transmit":98529496,"misc_node_boot_ts_seconds":1708493205,"misc_os":"linux","pid":7929,"pid_num_threads":15,"pid_mem_resident_set_size":78204928,"pid_mem_virtual_memory_size":806555648,"pid_mem_shared_memory_size":40501248,"pid_process_seconds_total":7}}
```



## To Do:
- Move CLI flags and options into config files

## Roadmap:
- Support localhost setup with Docker
- Develop ansible module to interact with geth/lighthouse
- Add validator vclient to load balancer
-- Need to deterministically generate api tokens for the validator API and/or automatically inject them during load balancing
