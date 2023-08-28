#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

CERT_ENDPOINT_LIST=$(vault secrets list -format=json  | jq -r 'to_entries[] | select( .value.type | test( "pki")) | .key | rtrimstr("/") ')

# For every PKI add the policies and roles
for CERT_ENDPOINT in ${CERT_ENDPOINT_LIST}
do

    # Add PKI Role to PKI
    vault secrets disable ${CERT_ENDPOINT}

done

vault auth disable approle
