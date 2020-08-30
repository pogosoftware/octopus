#!/bin/bash

kubectl config view --raw -o json | jq -r ".users[] | select(.name==\"kubernetes-admin\") | .user[\"client-certificate-data\"]" | base64 -d > client.crt
kubectl config view --raw -o json | jq -r ".users[] | select(.name==\"kubernetes-admin\") | .user[\"client-key-data\"]" | base64 -d > client.key
kubectl config view --raw -o json | jq -r ".clusters[] | select(.name==\"kubernetes\") | .cluster[\"certificate-authority-data\"]" | base64 -d > /vagrant/certs/cluster.crt
openssl pkcs12 -export -in client.crt -inkey client.key -out /vagrant/certs/client.pfx -passout pass:
rm client.crt
rm client.key