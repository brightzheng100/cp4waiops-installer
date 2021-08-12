#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-common-services-pre {
    #
    # Create namespace for Common Services
    #
    execlog oc new-project $NAMESPACE_CS
}

function install-common-services-operators {
    #
    # Operators
    #
    execlog 'envsubst < manifests/common-services-operators.yaml | oc apply -f -'
}

function install-common-services-crs {
    #
    # CRs
    #

    # Note: nothing to do as of v3.1.1
    log 'No specific CRs are required for the Common Services'
    #execlog 'envsubst < manifests/common-services-cr.yaml | oc apply -f -'
}