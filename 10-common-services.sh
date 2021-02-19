#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-common-services {

    #
    # Create namespace for Common Services
    #
    execlog oc new-project $NAMESPACE_CS

    #
    # Operators
    #
    execlog 'envsubst < manifests/common-services-operators.yaml | oc apply -f -'

    # Wait for 1 min
    progress-bar 1

    # Create IBM Licensing instance
    execlog 'envsubst < manifests/common-services-cr.yaml | oc apply -f -'

}