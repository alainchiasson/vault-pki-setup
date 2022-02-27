#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

# Create a random approle
tmpfile=$(mktemp)
APP_ROLE=${tmpfile#/tmp/tmp.}

# Get all PKI_Policy=pki_role_.* and append base policies. ( this would cause a security issue - pki_role_* )
vault policy list -format=json | jq '.[] | select( test("pki_role_.*")) |  { "token_policies": [ . , "read_current_cert", "default"] }' > ${tmpfile}

# Create an App_role with PKI Policies
vault write auth/approle/role/${APP_ROLE} @${tmpfile}

CERT_ENDPOINT_LIST=$(vault secrets list -format=json  | jq -r 'to_entries[] | select( .value.type | test( "pki")) | .key | rtrimstr("/") ')

# For every PKI add the policies and roles
for CERT_ENDPOINT in ${CERT_ENDPOINT_LIST}
do

    # Add PKI Role to PKI
    vault write ${CERT_ENDPOINT}/roles/${APP_ROLE} allowed_domains="${APP_ROLE}" allow_bare_domains=true

done
