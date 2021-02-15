#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-event-manager {
    export ocp_cluster_domain="$(oc get route -n openshift-ingress router-default -o json | jq -r .spec.host | cut -d"." -f2-)"

    execlog 'envsubst < manifests/event-manager.yaml | oc apply -f -'
}

function how-to-access-event-manager {
    local url="$( oc get route -n $NAMESPACE_CP4AIOPS noi-webgui-oauth2 -o json | jq -r .spec.host )"
    local username="icpadmin"
    local password="$(oc get secret noi-icpadmin-secret -n $NAMESPACE_CP4AIOPS  -ojsonpath={.data.ICP_ADMIN_PASSWORD} | base64 --decode)"
    
    log "========================================================"
    log "Here is the info for how to access Event Manager:"
    log "- URL: $url"
    log "- username: $username"
    log "- password: $password"
    log "========================================================"
}
