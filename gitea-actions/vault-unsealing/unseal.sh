#!/bin/bash

# Set the IP address of your Consul server
CONSUL_IP="192.168.50.13"

# Read the unseal key from file
UNSEAL_KEY1=$1
UNSEAL_KEY2=$2
UNSEAL_KEY3=$3

# Set the IP addresses to check
IPS=("192.168.50.11" "192.168.50.12" "192.168.50.13" "192.168.50.14" "192.168.50.15")

# Loop over the IP addresses
for IP in "${IPS[@]}"
do
  # Check if the Vault service is sealed on the current IP
  RESPONSE=$(curl -sS --request GET "http://${IP}:8200/v1/sys/seal-status")
  SEALED=$(echo $RESPONSE | jq -r '.sealed')

  # If the service is sealed, unseal it
  if [ "$SEALED" = "true" ]
  then
    echo "Vault service is sealed on IP $IP"

    # Call the Vault API to unseal the service
    curl -sS --header "X-Vault-Token: $VAULT_TOKEN" --request PUT --data "{\"key\":\"$UNSEAL_KEY1\"}" "http://${IP}:8200/v1/sys/unseal"
    curl -sS --header "X-Vault-Token: $VAULT_TOKEN" --request PUT --data "{\"key\":\"$UNSEAL_KEY2\"}" "http://${IP}:8200/v1/sys/unseal"
    curl -sS --header "X-Vault-Token: $VAULT_TOKEN" --request PUT --data "{\"key\":\"$UNSEAL_KEY3\"}" "http://${IP}:8200/v1/sys/unseal"
  else
    echo "Vault service is unsealed on IP $IP"
  fi
done

