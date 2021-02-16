#!/bin/bash

source lib/utils.sh

#
# Defaults to long to "_logs/" folder
# 
export LOGDIR="${LOGDIR:-$(PWD)/_logs}"
mkdir -p "$LOGDIR"
export LOGFILE="$LOGDIR/install-$(date +"%Y-%m-%d").log"

#
# Entitlement
#
if [ -z "${ENTITLEMENT_KEY}" ] | [ -z "${ENTITLEMENT_EMAIL}" ]; then 
  log "You must export the ENTITLEMENT_KEY and ENTITLEMENT_EMAIL environment variables prior to installation. For example"
  log "export ENTITLEMENT_KEY=XXXX"
  log "export ENTITLEMENT_EMAIL=myemail@ibm.com"
  exit 999;
fi

#
# Namespaces
# 
export NAMESPACE_CS="${NAMESPACE_CS:-ibm-common-services}"
export NAMESPACE_CP4AIOPS="${NAMESPACE_CP4AIOPS:-ibm-cp4aiops}"
export NAMESPACE_HUMIO="${NAMESPACE_HUMIO:-humio}"

#
# StorageClass
#
export STORAGECLASS_FILE="${STORAGECLASS_FILE:-ibmc-file-gold-gid}"

#
# Humio
#
# Humio Operator Version
export HUMIO_OPERATOR_VERSION="${HUMIO_OPERATOR_VERSION:-0.5.0}"
