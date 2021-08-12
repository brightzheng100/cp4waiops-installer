#!/bin/bash

source lib/utils.sh
source lib/status.sh
source 21-aiops-post-actions.sh

function install-aiops-pre {
    #
    # Create namespace for Common Services
    #
    execlog oc new-project $NAMESPACE_CP4WAIOPS

    # Create the entitlement key secret
    execlog oc create secret docker-registry 'ibm-entitlement-key' --docker-server="cp.icr.io" --docker-username="cp" --docker-password="$ENTITLEMENT_KEY" --docker-email="$ENTITLEMENT_EMAIL" --namespace="$NAMESPACE_CP4WAIOPS"

    # Create CatalogSources
    execlog 'oc apply -f manifests/aiops-catalogsources.yaml'
}

function install-aiops-operators {
    # Install the AI Ops Operators
    execlog 'oc apply -f manifests/aiops-operators.yaml'
}

function install-aiops-cr {
    # Install the AI Ops Operators
    execlog 'envsubst < manifests/aiops-cr.yaml | oc apply -f -'
}

#
# Calling post actions from 21-aiops-post-actions.sh
#
function install-aiops-post-actions {
    # Update the AIOps cert
    update-aiops-cert

    # Install Event Manager Gateway to enable event data to flow from the event management component to the AI Manager
    install-event-manager-gateway
}

function how-to-access-aiops-console {
    local url="$( oc get route -n $NAMESPACE_CP4WAIOPS cpd -o jsonpath='{.spec.host}' )"
    local username="$( oc -n $NAMESPACE_CS get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d && echo )"
    local password="$( oc -n $NAMESPACE_CS get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d )"
    
    log "========================================================"
    log "Here is the info for how to access IBM Cloud Pak for Watson AIOps console:"
    log "- URL: $url"
    log "- username: $username"
    log "- password: $password"
    log "========================================================"
}
