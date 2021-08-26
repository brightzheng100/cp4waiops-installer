#!/bin/bash

source lib/utils.sh
source lib/status.sh
source lib/status.sh
source 00-setup.sh

# 60 - Turbonomic
function uninstall-turbonomic {
    # CRs
    envsubst < integration/turbonomic/turbonomic-cr.yaml | oc delete -f -
    # Operator
    envsubst < integration/turbonomic/turbonomic-operators.yaml | oc delete -f -
    # Project
    oc delete project $NAMESPACE_TURBONOMIC
}

# 51 - OpenShift Logging

# 50 - Humio
function uninstall-humio {
    # Humio Cluster
    envsubst < integration/humio/humio-cluster.yaml | oc delete -f -
    # Kafka
    envsubst < integration/humio/humio-kafka.yaml | oc delete -f -
    # Operator
    helm delete humio-operator --namespace $NAMESPACE_HUMIO
}

# 50 - Humio post actions
function uninstall-humio-post-actions {
    # PVCs
    pvcs=( \
        data-kafka-cluster-kafka-0 \
        data-kafka-cluster-zookeeper-0 \
    )
    for pvc in "${pvcs[@]}"
    do
        oc patch pvc $pvc -p '{"metadata":{"finalizers":null}}' -n $NAMESPACE_HUMIO
        oc delete pvc $pvc --grace-period=0 --force -n $NAMESPACE_HUMIO &
    done
}

# 20 - Watson AIOps
function uninstall-aiops {
    # CRs
    envsubst < manifests/aiops-cr.yaml | oc delete -f -
    # Operators
    envsubst < manifests/aiops-operators.yaml | oc delete -f -
    # CatalogSources
    envsubst < manifests/aiops-catalogsources.yaml | oc delete -f -
}

# 20 - Watson AIOps post actions
function uninstall-aiops-post-actions {
    # Some extra objects that require to clean up
    oc delete ZenService/iaf-zen-cpdservice -n $NAMESPACE_CP4WAIOPS
    oc delete Elasticsearch.elastic.automation.ibm.com/iaf-system -n $NAMESPACE_CP4WAIOPS
    # PVCs
    pvcs=(`oc -n $NAMESPACE_CP4WAIOPS get pvc -o json | jq -r '.items[].metadata.name'`)
    for pvc in "${pvcs[@]}"
    do
        oc patch pvc $pvc -p '{"metadata":{"finalizers":null}}' -n $NAMESPACE_CP4WAIOPS
        oc delete pvc $pvc --grace-period=0 --force -n $NAMESPACE_CP4WAIOPS &
    done
}

# 12 - OpenShift Serverless
function uninstall-openshift-serverless {
    oc -n openshift-serverless delete -f manifests/openshift-serverless-cr.yaml
    oc -n openshift-serverless delete -f manifests/openshift-serverless-operators.yaml
    oc delete project openshift-serverless
}

# 11 - LDAP
function uninstall-ldap {
    oc -n $NAMESPACE_LDAP delete -f integration/ldap/openldap.yaml
    oc delete project $NAMESPACE_LDAP
}

# 10 - Common Services
function uninstall-common-services {
    #envsubst < manifests/common-services-cr.yaml | oc delete -f -
    envsubst < manifests/common-services-operators.yaml | oc delete -f -
}