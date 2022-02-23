#!/usr/bin/env bash
#
vault login root

role_id=$(vault read -field=role_id auth/approle/role/server/role-id)
secret_id=$(vault write -field=secret_id -f auth/approle/role/server/secret-id)

export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=$role_id secret_id=$secret_id)

# Get Cert endpoint vault kv write secret/current_cert cert_endpoint=pki_int_0
export CERT_ENDPOINT=$(vault kv get -field=cert_endpoint secret/current_cert)

# First method - auth and get all
vault write -format=json ${CERT_ENDPOINT}/issue/server common_name="server" alt_name="server" ttl="24h" > server.json

jq -r '.data.ca_chain'      server.json > server.chain.pem
jq -r '.data.certificate'   server.json > server.cert.pem
jq -r '.data.issuing_ca'    server.json > server.ca.pem
jq -r '.data.private_key'   server.json > server.key.pem
jq -r '.data.serial_number' server.json > server.ser.pem


unset VAULT_TOKEN

curl -s http://vault:8200/v1/pki_root/ca/pem > root.cert.pem
echo >> root.cert.pem
curl -s http://vault:8200/v1/pki_int_0/ca/pem > int_0.cert.pem
echo >> int_0.cert.pem
curl -s http://vault:8200/v1/pki_int_1/ca/pem > int_1.cert.pem
echo >> int_1.cert.pem
curl -s http://vault:8200/v1/pki_int_2/ca/pem > int_2.cert.pem
echo >> int_2.cert.pem

cat root.cert.pem int_0.cert.pem int_1.cert.pem int_2.cert.pem > common.cert.pem