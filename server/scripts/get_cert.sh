#!/usr/bin/env bash
#
vault login root

role_id=$(vault read -field=role_id auth/approle/role/server/role-id)
secret_id=$(vault write -field=secret_id -f auth/approle/role/server/secret-id)

export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$role_id secret_id=$secret_id)

# First method - auth and get all
vault write -format=json pki_int/issue/server common_name="server" ttl="24h" > server.json

jq -r '.data.ca_chain'      server.json > server.chain.pem
jq -r '.data.certificate'   server.json > server.cert.pem
jq -r '.data.issuing_ca'    server.json > server.ca.pem
jq -r '.data.private_key'   server.json > server.key.pem
jq -r '.data.serial_number' server.json > server.ser.pem

unset VAULT_TOKEN

curl -s http://vault:8200/v1/pki_root/ca/pem > root.cert.pem
echo >> root.cert.pem
curl -s http://vault:8200/v1/pki_int/ca/pem > int.cert.pem
echo >> int.cert.pem

cat root.cert.pem int.cert.pem  > common.cert.pem
