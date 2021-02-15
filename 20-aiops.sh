#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-aiops {

    #
    # Create namespace for Common Services
    #
    execlog oc new-project $NAMESPACE_CP4AIOPS

    # cp.icr.io is required for Watson AIOps.
    execlog oc create secret docker-registry 'cp.icr.io' --docker-server="cp.icr.io" --docker-username="cp" --docker-password="$ENTITLEMENT_KEY" --docker-email="$ENTITLEMENT_EMAIL" --namespace="$NAMESPACE_CP4AIOPS"
    # cp.stg.icr.io is required for AI Manager
    execlog oc create secret docker-registry 'cp.stg.icr.io' --docker-server="cp.icr.io" --docker-username="cp" --docker-password="$ENTITLEMENT_KEY" --docker-email="$ENTITLEMENT_EMAIL" --namespace="$NAMESPACE_CP4AIOPS"

    # Install the AI Ops Operators
    execlog 'envsubst < manifests/aiops-operators.yaml | oc apply -f -'

}