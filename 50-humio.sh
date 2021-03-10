#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-humio {
  # Create a project for Humio
  execlog "oc new-project $NAMESPACE_HUMIO"

  # Install a dedicated Kafka instance powered by Strimzi for Humio
  execlog 'envsubst < manifests/humio/humio-kafka.yaml | oc apply -f -'

  # Install Humio CRDs
  execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioclusters.yaml"
  execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioexternalclusters.yaml"
  execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioingesttokens.yaml"
  execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioparsers.yaml"
  execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humiorepositories.yaml"
  execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioviews.yaml"

  # Add Humio to Helm repo
  execlog "helm repo add humio-operator https://humio.github.io/humio-operator"
  execlog "helm repo update"

  # Install Humio Operator by Helm v3+
  execlog "helm install humio-operator humio-operator/humio-operator --namespace $NAMESPACE_HUMIO --version $HUMIO_OPERATOR_VERSION --set openshift=true"
  # Create Humio Cluster
  if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then 
    execlog 'envsubst < manifests/humio/humio-cluster-with-ldap.yaml | oc apply -f -'
  else
    execlog 'envsubst < manifests/humio/humio-cluster.yaml | oc apply -f -'
  fi
}

function install-humio-post-actions {
  # If LDAP is integrated, add the root access acount to admins
  # Ref: https://docs.humio.com/docs/security/root-access/
  if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then
    local POD=$(oc -n $NAMESPACE_HUMIO get pod -l app.kubernetes.io/instance=humio-cluster -o jsonpath="{.items[0].metadata.name}")
    local TOKEN=$(oc -n $NAMESPACE_HUMIO exec $POD -c auth -- cat /data/humio-data/local-admin-token.txt)

    execlog oc -n $NAMESPACE_HUMIO exec $POD -c auth -- curl -s http://127.0.0.1:8080/api/v1/users -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"email\": \"admin1\", \"isRoot\": true}"
    execlog oc -n $NAMESPACE_HUMIO exec $POD -c auth -- curl -s http://127.0.0.1:8080/api/v1/users -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"email\": \"admin2\", \"isRoot\": true}"
  fi
}

function how-to-access-humio {
  local url="$( oc get route -n $NAMESPACE_HUMIO humio-cluster -o json | jq -r .spec.host )"

  if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then
    local password="secret" # it's hardcoded in integration/ldap/ldif/*.ldif

    log "========================================================"
    log "Since LDAP is integrated, all these accounts can be used to access Humio:"
    log "- URL: $url"
    log "- password: secret"
    log "- admin users:"
    local adminpassword=Passw0rd
    execlog "oc -n ldap exec $POD -- ldapsearch -LLL -x -H ldap:// -D \"cn=admin,dc=bright,dc=com\" -w $adminpassword -b \"ou=people,dc=bright,dc=com\" \"(uid=admin*)\" uid | grep \"uid:\" | cut -d: -f2"
    log "- normal users:"
    execlog "oc -n ldap exec $POD -- ldapsearch -LLL -x -H ldap:// -D \"cn=admin,dc=bright,dc=com\" -w $adminpassword -b \"ou=people,dc=bright,dc=com\" \"(uid=developer*)\" uid | grep \"uid:\" | cut -d: -f2"
    log "========================================================"
  else
    local username="developer"
    local password="password" # it's hardcoded in "humio-cr.yaml" for now:)
    
    log "========================================================"
    log "Here is the info for how to access Humio:"
    log "- URL: $url"
    log "- username: $username"
    log "- password: $password"
    log "========================================================"
  fi
}
