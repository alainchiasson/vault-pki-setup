#!/usr/bin/env bash
# Manage issuing is a quick utility to rotate issung certificates.
#

# Using a preset Vault Root Token 
vault login root

# Get List of PKI's 
CERT_ENDPOINT_LIST=$(vault secrets list -format=json  | jq -r 'to_entries[] | select( .value.type | test( "pki")) | .key | rtrimstr("/") ')

# For every PKI add the policies and roles
for CERT_ENDPOINT in ${CERT_ENDPOINT_LIST}
do

    # Pull the Cert 
    curl -s http://vault:8200/v1/${CERT_ENDPOINT}/ca/pem > ${CERT_ENDPOINT}.cert.pem
    echo >>  ${CERT_ENDPOINT}.cert.pem

    # If it is expired
    CERT_END=$( openssl x509 -enddate -noout -in pki_int_202203022032.cert.pem | cut -d = -f 2 )
    if [[ $(date +%s --date="$CERT_END") < $(date +%s) ]]; then

        remove_issuer.sh ${CERT_ENDPOINT}
    
    fi

done


