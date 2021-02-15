#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-humio {
  # Create a project for Humio
  execlog "oc new-project $NAMESPACE_HUMIO"

  # Install a dedicated Kafka instance powered by Strimzi for Humio
  execlog 'envsubst < manifests/humio/humio-kafka.yaml | oc apply -f -'

  # Add Humio to Helm repo
  execlog "helm repo add humio-operator https://humio.github.io/humio-operator"
  execlog "helm repo update"

  # Install Humio Operator by Helm v3+
  execlog "helm install humio-operator humio-operator/humio-operator --namespace $NAMESPACE_HUMIO --version $HUMIO_OPERATOR_VERSION --set installCRDs=true --set openshift=true"
  # Create Humio CRs
  execlog 'envsubst < manifests/humio/humio-cr.yaml | oc apply -f -'
}

function how-to-access-humio {
    local url="$( oc get route -n $NAMESPACE_HUMIO humio-cluster -o json | jq -r .spec.host )"
    local username="developer"
    local password="password" # it's hardcoded in "humio-cr.yaml" for now:)
    
    log "========================================================"
    log "Here is the info for how to access Humio:"
    log "- URL: $url"
    log "- username: $username"
    log "- password: $password"
    log "========================================================"
}
