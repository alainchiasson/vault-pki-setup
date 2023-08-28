#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

# Enable the pki
vault secrets enable -path=pki_root pki

# generate root certificates ( and export )
vault write -format=json /pki_root/root/generate/exported common_name="Dev Root" > root.json

jq -r '.data.certificate'   root.json > root.cert.pem
jq -r '.data.issuing_ca'    root.json > root.ca.pem
jq -r '.data.private_key'   root.json > root.key.pem
jq -r '.data.serial_number' root.json > root.serial.pem

# Enaable Approles
vault auth enable approle

#
vault policy write read_current_cert - <<EOF
path "secret/data/current_cert" {
    capabilities = ["read"]
}

EOF

# Create a pki App_role
vault write auth/approle/role/client token_policies=default,read_current_cert
vault write auth/approle/role/server token_policies=default,read_current_cert

