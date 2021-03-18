#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-aimanager {
  # Delete `aimanager` operator from `ibm-watson-aiops-catalog`
  execlog "oc delete Subscription aimanager-operator-v1.0-ibm-watson-aiops-catalog-openshift-marketplace -n $NAMESPACE_CP4AIOPS | true"
  execlog "oc delete csv aimanager-operator.v1.0.0 -n $NAMESPACE_CP4AIOPS | true"

  # Install AI Manager
  execlog 'envsubst < manifests/aimanager.yaml | oc apply -f -'
}

function how-to-access-aimanager {
    local url="$( oc get route -n $NAMESPACE_CP4AIOPS ibm-cp4aiops-cpd -o json | jq -r .spec.host )"
    local username="admin"
    local password="$( oc get secret admin-user-details -n $NAMESPACE_CP4AIOPS  -ojsonpath={.data.initial_admin_password} | base64 --decode )"
    
    log "========================================================"
    log "Here is the info for how to access AI Manager:"
    log "- URL: $url"
    log "- username: $username"
    log "- password: $password"
    log "========================================================"
}
