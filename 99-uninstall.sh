#!/bin/bash

source lib/utils.sh
source lib/status.sh
source 00-setup.sh

# Humio
function uninstall-humio {
    # Operators, Instance & Helm Chart
    envsubst < manifests/humio/humio-kafka.yaml | oc delete -f -
    envsubst < manifests/humio/humio-cr.yaml | oc delete -f -
    helm delete humio-operator --namespace $NAMESPACE_HUMIO
}
function uninstall-humio-post-actions {
    # PVCs
    pvcs=( \
        data-kafka-cluster-kafka-0 \
        data-kafka-cluster-zookeeper-0 \
    )
    for pvc in "${pvcs[@]}"
    do
        oc patch pvc $pvc -p '{"metadata":{"finalizers":null}}' -n $NAMESPACE_HUMIO
        oc delete pvc $pvc --grace-period=0 --force -n $NAMESPACE_HUMIO
    done
}

# Event Manager
function uninstall-event-manager {
    envsubst < manifests/event-manager.yaml | oc delete -f -
}

# AI Manager
function uninstall-aimanager {
    # Operators, Instance & PVCs
    envsubst < manifests/aimanager.yaml | oc delete -f -
}
function uninstall-aimanager-post-actions {
    # PVCs
    pvcs=( \
        cpd-install-operator-pvc \
        cpd-install-shared-pvc \
        data-strimzi-cluster-kafka-0 \
        data-strimzi-cluster-zookeeper-0 \
        datadir-zen-metastoredb-0 \
        datadir-zen-metastoredb-1 \
        datadir-zen-metastoredb-2 \
        elasticsearch-ibm-elasticsearch-ibm-elasticsearch-data-elasticsea-cd98-ib-6fb9-es-server-all-0 \
        export-aimanager-ibm-minio-0 \
        export-aimanager-ibm-minio-1 \
        export-aimanager-ibm-minio-2 \
        export-aimanager-ibm-minio-3 \
        influxdb-pvc \
        stolon-data-aimanager-postgres-keeper-0 \
        user-home-pvc \
        aimanager-ibm-flink-job-manager-recovery-pvc \
    )
    for pvc in "${pvcs[@]}"
    do
        oc patch pvc $pvc -p '{"metadata":{"finalizers":null}}' -n $NAMESPACE_CP4AIOPS
        oc delete pvc $pvc --grace-period=0 --force -n $NAMESPACE_CP4AIOPS
    done
}

# Watson AIOps
function uninstall-aimanager {
    # Operators
    envsubst < manifests/aiops-operators.yaml | oc delete -f -
}

# Common Services
function uninstall-common-services {
    envsubst < manifests/common-services-cr.yaml | oc delete -f -
    envsubst < manifests/common-services-operators.yaml | oc delete -f -
}
