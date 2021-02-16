#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-humio {
  # Create a project for Humio
  execlog "oc new-project $NAMESPACE_HUMIO"

  # Install a dedicated Kafka instance powered by Strimzi for Humio
  execlog 'envsubst < manifests/humio/humio-kafka.yaml | oc apply -f -'

  # Install Humio CRDs
  oc apply -f "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioclusters.yaml"
  oc apply -f "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioexternalclusters.yaml"
  oc apply -f "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioingesttokens.yaml"
  oc apply -f "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioparsers.yaml"
  oc apply -f "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humiorepositories.yaml"

  # Add Humio to Helm repo
  execlog "helm repo add humio-operator https://humio.github.io/humio-operator"
  execlog "helm repo update"

  # Install Humio Operator by Helm v3+
  execlog "helm install humio-operator humio-operator/humio-operator --namespace $NAMESPACE_HUMIO --version $HUMIO_OPERATOR_VERSION --set openshift=true"
  # Create Humio Cluster
  execlog 'envsubst < manifests/humio/humio-cluster.yaml | oc apply -f -'
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
