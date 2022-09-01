Install Vault

```bash
vault login
vault secrets enable -version=2 -path=secrets kv
```

```bash
vault put secrets/proxmox/token id=<proxmoxTokenId>
vault patch secrets/proxmox/token secret=<proxmoxTokenSecret>
```

```bash
export VAULT_ADDR=
export VAULT_TOKEN=`cat ~/.vault-token`
```
