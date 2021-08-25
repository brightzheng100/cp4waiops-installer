#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-humio-pre {
  # Create a project for Humio
  execlog "oc new-project $NAMESPACE_HUMIO"
}

function install-humio-operators {
  # Install a dedicated Kafka instance powered by Strimzi for Humio
  execlog 'envsubst < integration/humio/humio-kafka.yaml | oc apply -f -'

  # Install Humio CRDs
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioclusters.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioexternalclusters.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioingesttokens.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioparsers.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humiorepositories.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioviews.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioalerts.yaml"
  # execlog "oc apply -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-$HUMIO_OPERATOR_VERSION/config/crd/bases/core.humio.com_humioactions.yaml"

  # Add Humio to Helm repo
  execlog "helm repo add humio-operator https://humio.github.io/humio-operator"
  execlog "helm repo update"

  # Install Humio Operator by Helm v3+
  execlog "helm install humio-operator humio-operator/humio-operator --namespace $NAMESPACE_HUMIO --version $HUMIO_OPERATOR_VERSION --set installCRDs=true --set openshift=true --set resources.limits.memory=500Mi"
}

function install-humio-cluster {
  # Create license
  # Please note that the license file can be prepared through the installation process or beforehand.
  execlog "oc create secret generic humio-license --from-file=data=./_humio_license.txt"
  
  # Create Humio Cluster
  if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then 
    execlog 'envsubst < integration/humio/humio-cluster-with-ldap.yaml | oc apply -f -'
  else
    execlog 'envsubst < integration/humio/humio-cluster.yaml | oc apply -f -'
  fi
}

function install-humio-crs {
  # Create CRs
  execlog 'envsubst < integration/humio/humio-cr.yaml | oc apply -f -'
}

function install-humio-post-actions {
  # If LDAP is integrated, add the root access acount to admins
  # Ref: https://docs.humio.com/docs/security/root-access/
  if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then
    local POD=$(oc -n $NAMESPACE_HUMIO get pod -l app.kubernetes.io/instance=humio-cluster -o jsonpath="{.items[0].metadata.name}")
    local TOKEN=$(oc -n $NAMESPACE_HUMIO exec $POD -c auth -- cat /data/humio-data/local-admin-token.txt)

    oc -n $NAMESPACE_HUMIO exec $POD -c auth -- curl -s http://127.0.0.1:8080/api/v1/users -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"email": "admin1", "isRoot": true}'
    echo ""
    log "admin1 has been promoted as admin"
    oc -n $NAMESPACE_HUMIO exec $POD -c auth -- curl -s http://127.0.0.1:8080/api/v1/users -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"email": "admin2", "isRoot": true}'
    echo ""
    log "admin2 has been promoted as admin"
  fi
}

function how-to-access-humio {
  local route="$( oc get route -n $NAMESPACE_HUMIO humio-cluster -o json | jq -r .spec.host )"

  if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then
    local password="secret"     # it's hardcoded in integration/ldap/ldif/*.ldif
    local POD=$(oc -n ldap get pod -l app.kubernetes.io/name=openldap -o jsonpath="{.items[0].metadata.name}")

    log "========================================================"
    log "Since LDAP is integrated, all these accounts can be used to access Humio:"
    log "- URL: http://$route"
    log "- password: secret"
    log "- admin users:"
    execlog "oc -n ldap exec $POD -- ldapsearch -LLL -x -H ldap:// -D \"cn=admin,dc=bright,dc=com\" -w $LDAP_ADMIN_PASSWORD -b \"ou=people,dc=bright,dc=com\" \"(uid=admin*)\" uid | grep \"uid:\" | cut -d: -f2"
    log "- normal users:"
    execlog "oc -n ldap exec $POD -- ldapsearch -LLL -x -H ldap:// -D \"cn=admin,dc=bright,dc=com\" -w $LDAP_ADMIN_PASSWORD -b \"ou=people,dc=bright,dc=com\" \"(uid=developer*)\" uid | grep \"uid:\" | cut -d: -f2"
    log "========================================================"
  else
    local username="developer"
    local password="password"     # it's hardcoded in "humio-cr.yaml" for now if no LDAP is integrated:)
    
    log "========================================================"
    log "Here is the info for how to access Humio:"
    log "- URL: http://$route"
    log "- username: $username"
    log "- password: $password"
    log "========================================================"
  fi
}
