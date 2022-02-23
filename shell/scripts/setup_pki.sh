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

# Create 3 new intermediates
for x in 0 1 2
do
    # generate intermediate certs for rotation
    #
    vault secrets enable -path=pki_int_$x pki

    vault write -format=json /pki_int_$x/intermediate/generate/exported common_name="EAN Issuing Dev $x" > iss-$x-gen.json

    jq -r '.data.csr'               iss-$x-gen.json > iss-$x.csr.pem
    jq -r '.data.private_key'       iss-$x-gen.json > iss-$x.key.pem

    vault write -format=json /pki_root/root/sign-intermediate csr=@iss-$x.csr.pem common_name="EAN Issuing Dev $x" > iss-$x-sig.json

    jq -r '.data.certificate'       iss-$x-sig.json > iss-$x.cert.pem
    jq -r '.data.issuing_ca'        iss-$x-sig.json > iss-$x.ca.pem
    jq -r '.data.serial'            iss-$x-sig.json > iss-$x.ser.pem

    # Write certificate to issung

    vault write -format=json /pki_int_$x/intermediate/set-signed certificate=@iss-$x.cert.pem 

done
# Establish link on  premissions
# Enaable Approles
vault auth enable approle
APPROLE_ACCESSOR=$(vault auth list -format=json | jq -r '."approle/".accessor')

# Set up a general policy for pki access - link PKI name with Approle Role.

vault policy write pki_role - <<EOF

path "pki_int_0/issue/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["read","update"]
}
path "pki_int_1/issue/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["read","update"]
}
path "pki_int_2/issue/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["read","update"]
}
path "secret/data/current_cert" {
    capabilities = ["read"]
}

EOF

# Create a pki App_role
vault write auth/approle/role/client token_policies=default,pki_role
# Setup pki role
vault write pki_int_0/roles/client allowed_domains="client" allow_bare_domains=true
vault write pki_int_1/roles/client allowed_domains="client" allow_bare_domains=true
vault write pki_int_2/roles/client allowed_domains="client" allow_bare_domains=true

# Create a pki App_role
vault write auth/approle/role/server token_policies=default,pki_role
# Setup pki role
vault write pki_int_0/roles/server allowed_domains="server" allow_bare_domains=true
vault write pki_int_1/roles/server allowed_domains="server" allow_bare_domains=true
vault write pki_int_2/roles/server allowed_domains="server" allow_bare_domains=true

# Set initial int certificate location
echo "Set int_endpoint to pki_int_0"

vault kv put secret/current_cert cert_endpoint=pki_int_0


