#!/usr/bin/env bash
# Manage issuing is a quick utility to rotate issung certificates.
#

# Using a preset Vault Root Token 
vault login root

# generate intermediate certs for rotation
#
# For demos and testing - issuing certs expire real soon
cert_end=$(date --date='+3 days' +%Y%m%d%H%M)

vault secrets enable -path=pki_int_$cert_end pki

# Generate New CSR
vault write -format=json /pki_int_$cert_end/intermediate/generate/exported common_name="DEV Issuing $cert_end" > iss-$cert_end-gen.json

jq -r '.data.csr'               iss-$cert_end-gen.json > iss-$cert_end.csr.pem
jq -r '.data.private_key'       iss-$cert_end-gen.json > iss-$cert_end.key.pem

# Sign new Issuing cert
vault write -format=json /pki_root/root/sign-intermediate csr=@iss-$cert_end.csr.pem common_name="DEV Issuing $cert_end" > iss-$cert_end-sig.json

jq -r '.data.certificate'       iss-$cert_end-sig.json > iss-$cert_end.cert.pem
jq -r '.data.issuing_ca'        iss-$cert_end-sig.json > iss-$cert_end.ca.pem
jq -r '.data.serial'            iss-$cert_end-sig.json > iss-$cert_end.ser.pem

# Write Signed Issuning to Vault.
vault write -format=json /pki_int_$cert_end/intermediate/set-signed certificate=@iss-$cert_end.cert.pem 

# Establish new policy ( for approle accessor )
APPROLE_ACCESSOR=$(vault auth list -format=json | jq -r '."approle/".accessor')

vault policy write pki_int_$cert_end - <<EOF

path "pki_int_${cert_end}/issue/{{identity.entity.aliases.${APPROLE_ACCESSOR}.metadata.role_name}}" {
    capabilities = ["read","update"]
}

EOF

# Loop through AppRoles and add policy
APP_ROLE_LIST=$(vault list -format=json auth/approle/role | jq -r .[])

for APP_ROLE in ${APP_ROLE_LIST}
do
    # Add Policy to AppRole.
    tmpfile=$(mktemp)
    vault read -format=json auth/approle/role/${APP_ROLE} | jq " [ \"pki_int_${cert_end}\" ] + .data.token_policies | { \"token_policies\": . }" > ${tmpfile}
    vault write auth/approle/role/${APP_ROLE} @${tmpfile}

    # Add PKI Role to PKI
    vault write pki_int_${cert_end}/roles/${APP_ROLE} allowed_domains="${APP_ROLE}" allow_bare_domains=true

done

# Set initial int certificate location
echo "Set int_endpoint to pki_int_${cert_end}"

vault kv put secret/current_cert cert_endpoint=pki_int_${cert_end}
