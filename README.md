# A Simplified Installation Guide for IBM Watson AIOps

**Note:** This is not an IBM project and is provided **AS-IS**. Support is provided by community collaboration style at best effort only.

## Overview

This project is designed to provide an automated, simplified way to install a set of desired components of the IBM Watson AIOps v2.1.x, for POC / demo purposes only, on ROKS.

Currently there is a minimum set of components included in this installation exerience, which takes less than 1 hour:

- Dependent Common Services (~3mins)
- Event Manager (~10mins)
- AI Manager (~30mins)
- Humio (~5mins)

> Note: along the way, there might be more components to be added here.


## Get Started

**Prerequisites**

- `oc` command
- You must be authenticated to your OpenShift cluster with admin permissions
- [IBM Entitled Registry Key](https://myibm.ibm.com/products-services/containerlibrary) 
- Helm v3 CLI

**Process**

### 1. Clone the repo to local:

```sh
$ git clone https://github.com/brightzheng100/cp4aiops-installer.git
$ cd cp4aiops-installer
```


### 2. Export configurable variables:

There are quite some configurable variables to further customize the installation.

Please check out [00-setup.sh](./00-setup.sh) for details.

It's recommended to compile a local bash file so that we can export all customized variables without the need to change any existing files -- a file starting with `_` will be ignored by this repository so it's safe to keep it local and private only.

```sh
$ cat > _customization.sh <<EOF

#
# IBM Entitled Registry Credential
#
export ENTITLEMENT_KEY="<YOUR KEY GOES HERE>"
export ENTITLEMENT_EMAIL="<YOUR EMAIL GOES HERE>"

#
# Is it ROKS env? It defaults to ROKS but we may set it "false" explicitly
#
export ROKS="true"

#
# Storage Classes
#
export STORAGECLASS_FILE="ibmc-file-gold-gid"

EOF
```


### 3. Make sure you are in the project base folder to execute commands

```sh
# Source the customization we've compiled
$ source _customization.sh

# Make sure we've logged into OCP, then kick it off
$ ./install.sh
```

> Important Notes: 
> 1. A `install-<YYYY-mm-dd>.log` file will be generated to log the installation activities within the `_logs` folder under current folder, but you can change the folder by `export LOGDIR=<somewhere else>`;
> 2. To facilitate the retry UX, there is a way to skip some steps by exporting a list of `SKIP_STEPS`. For example: `export SKIP_STEPS="CS AIOPS"` is to instruct the installation process to skip installing `Common Services` and `AI Ops` objects. The available named steps are: 
>   - CS: Common Services
>   - AIOPS: AI Ops
>   - EVENTMANAGER: Event Manager
>   - AIMANAGER: AI Manager
>   - HUMIO: Humio


### 4. How to access?

At the end of the installation, the scripts will print out the access info, like URL, username/password, for major components.

But printing out the access info is also doable anytime after installation:

```sh
# Source the necessary
source _customization.sh && source 00-setup.sh

# Display how to access Event Manager
source 30-event-manager.sh
how-to-access-event-manager

# Display how to access AIManager
source 40-aimanager.sh
how-to-access-aimanager
```

## What's Next?

There are two major things we shall carry on:
- To make our components fully integrated;
- To build/use an app to run through an end-to-end demo.

So there will be two guides to be developed along the way:

### Integration Guide

TODO

### End-to-end Demo Guide

A simple demo guide will be provided to cover some typical use cases.

For example:
- A demo app -> logs to Humio -> AI Manager for log integration;
- Same demo app -> Event Manager -> AI Manager for event grouping, topology integration.

TODO

## Uninstall

To uninstall, run this:

```sh
source _customization.sh && source 00-setup.sh
./uninstall.sh
```

If you want to uninstall specific component(s), you can do this:

```sh
source _customization.sh && source 00-setup.sh  && source 99-uninstall.sh

# Uninstall only AIManager component
uninstall-aimanager
uninstall-aimanager-post-actions
```

> Note: you may have to run `./uninstall.sh` multiple times to uninstall all completely.

## Known Limitations / Issues

