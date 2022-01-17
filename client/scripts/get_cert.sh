#!/usr/bin/env bash
#
vault login root

role_id=$(vault read -field=role_id auth/approle/role/client/role-id)
secret_id=$(vault write -field=secret_id -f auth/approle/role/client/secret-id)

export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$role_id secret_id=$secret_id)

# First method - auth and get all
vault write -format=json pki_int/issue/client common_name="cl01@client" alt_name="client" ttl="24h" > client.json

jq -r '.data.ca_chain'      client.json > client.chain.pem
jq -r '.data.certificate'   client.json > client.cert.pem
jq -r '.data.issuing_ca'    client.json > client.ca.pem
jq -r '.data.private_key'   client.json > client.key.pem
jq -r '.data.serial_number' client.json > client.ser.pem

unset VAULT_TOKEN

curl -s http://vault:8200/v1/pki_root/ca/pem > root.cert.pem
echo >> root.cert.pem
curl -s http://vault:8200/v1/pki_int/ca/pem > int.cert.pem
echo >> int.cert.pem

cat root.cert.pem int.cert.pem  > common.cert.pem
