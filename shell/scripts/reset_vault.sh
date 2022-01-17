#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

vault secrets disable /pki_root
vault secrets disable /pki_int
#
vault auth disable approle