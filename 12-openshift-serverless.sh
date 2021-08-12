#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-openshift-serverless-pre {
    # Create a dedicated namespace
    execlog oc create namespace openshift-serverless || true
}

#
# This is to install OpenShift Serverless operators
#
function install-openshift-serverless-operators {
    # Create OpenShift Serverless operator
    execlog oc apply -f manifests/openshift-serverless-operators.yaml
}

#
# This is to install OpenShift Serverless CRs
#
function install-openshift-serverless-crs {
    # Create OpenShift Serverless CRs
    execlog oc apply -f manifests/openshift-serverless-cr.yaml
}

#
# post actions
#
function install-openshift-serverless-post {
    # Disable the route that provides unsecured access to Knative CLI
    oc annotate service.serving.knative.dev/kn-cli -n knative-serving serving.knative.openshift.io/disableRoute=true
}