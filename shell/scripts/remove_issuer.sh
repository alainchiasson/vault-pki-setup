#!/usr/bin/env bash
# Manage issuing is a quick utility to rotate issung certificates.
#
CERT_ENDPOINT=$1

# Using a preset Vault Root Token 
vault login root

# Loop through all AppRole and remove relavent policy
APP_ROLE_LIST=$(vault list -format=json auth/approle/role | jq -r .[])

for APP_ROLE in ${APP_ROLE_LIST}
do
    # Remove Policy from AppRole.
    tmpfile=$(mktemp)
    vault read -format=json auth/approle/role/${APP_ROLE} | jq ".data.token_policies - [ \"${CERT_ENDPOINT}\" ] | { \"token_policies\": . }" > ${tmpfile}
    vault write auth/approle/role/${APP_ROLE} @${tmpfile}

    # Add PKI Role to PKI
    vault write ${CERT_ENDPOINT}/roles/${APP_ROLE} allowed_domains="${APP_ROLE}" allow_bare_domains=true

done
# Delete Policies
vault policy delete ${CERT_ENDPOINT}

# Delete endpoint
vault secrets disable ${CERT_ENDPOINT}


