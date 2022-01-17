#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

# Enable the pki
vault secrets enable -path=pki_root pki

# generate root certificates ( and export )
vault write -format=json /pki_root/root/generate/exported common_name="Network HCV Root Dev" > root.json

jq -r '.data.certificate'   root.json > root.cert.pem
jq -r '.data.issuing_ca'    root.json > root.ca.pem
jq -r '.data.private_key'   root.json > root.key.pem
jq -r '.data.serial_number' root.json > root.serial.pem

# generate intermediate cert
#
vault secrets enable -path=pki_int pki

vault write -format=json /pki_int/intermediate/generate/exported common_name="EAN Issuing Dev" > iss-01-gen.json

jq -r '.data.csr'               iss-01-gen.json > iss-01.csr.pem
jq -r '.data.private_key'       iss-01-gen.json > iss-01.key.pem

vault write -format=json /pki_root/root/sign-intermediate csr=@iss-01.csr.pem common_name="EAN Issuing Dev" > iss-01-sig.json

jq -r '.data.certificate'       iss-01-sig.json > iss-01.cert.pem
jq -r '.data.issuing_ca'        iss-01-sig.json > iss-01.ca.pem
jq -r '.data.serial'            iss-01-sig.json > iss-01.ser.pem

# Write certificate to issung

vault write -format=json /pki_int/intermediate/set-signed certificate=@iss-01.cert.pem 

# Establish link on  premissions
# Enaable Approles
vault auth enable approle
APPROLE_ACCESSOR=$(vault auth list -format=json | jq -r '."approle/".accessor')

# Set up a general policy for pki access - link PKI name with Approle Role.

vault policy write pki_role - <<EOF

path "pki_int/issue/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["read","update"]
}
EOF

# Create a pki App_role
vault write auth/approle/role/client token_policies=default,pki_role
# Setup pki role
vault write pki_int/roles/client allowed_domains="client" allow_bare_domains=true

# Create a pki App_role
vault write auth/approle/role/server token_policies=default,pki_role
# Setup pki role
vault write pki_int/roles/server allowed_domains="server" allow_bare_domains=true
