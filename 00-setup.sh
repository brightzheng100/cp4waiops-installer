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
# Parameters
#
# Whether the env is ROKS
export ROKS="${ROKS:-true}"
# Default steps to be skipped
# Because Humio requires a dedicated license to be created as secret, skip it by default
export SKIP_STEPS="${SKIP_STEPS:-HUMIO}"

#
# Namespaces
# 
export NAMESPACE_CS="${NAMESPACE_CS:-ibm-common-services}"
export NAMESPACE_CP4WAIOPS="${NAMESPACE_CP4WAIOPS:-ibm-cp4waiops}"
export NAMESPACE_HUMIO="${NAMESPACE_HUMIO:-humio}"
export NAMESPACE_LDAP="${NAMESPACE_LDAP:-ldap}"
export NAMESPACE_OPENSHIFT_LOGGING="openshift-logging" # don't change for now
export NAMESPACE_TURBONOMIC="turbonomic"

#
# StorageClass
#
export STORAGECLASS_FILE="${STORAGECLASS_FILE:-ibmc-file-gold-gid}"
export STORAGECLASS_BLOCK="${STORAGECLASS_BLOCK:-ibmc-block-gold}"

#
# LDAP
#
export LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-Passw0rd}"

#
# Humio
#
# Humio is disabled by default
export HUMIO_ENABLED="${HUMIO_ENABLED:-false}"
# Humio Operator Version
export HUMIO_OPERATOR_VERSION="${HUMIO_OPERATOR_VERSION:-0.10.1}"
# Variable to control whether to integrate with LDAP
# Making it true will spin up the OpenLDAP in namespace "ldap", populated with data from integration/ldap/ldif/*.ldif
export HUMIO_WITH_LDAP_INTEGRATED="${HUMIO_WITH_LDAP_INTEGRATED:-false}"

#
# OpenShift Logging
#
# OpenShift Logging is disabled by default
export OPENSHIFT_LOGGING_ENABLED="${OPENSHIFT_LOGGING_ENABLED:-false}"

#
# Turbonomic
#
# Turbonomic is disabled by default
export TURBONOMIC_ENABLED="${TURBONOMIC_ENABLED:-false}"