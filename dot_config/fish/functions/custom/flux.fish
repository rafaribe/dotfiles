# Flux Reconcile Terraform
# usage: frt authentik will run flux reconcile source oci terraform-authentik-oci
function frt --description "frt authentik will run flux reconcile source oci terraform-authentik-oci"
    set argument $argv[1]
    flux reconcile source oci terraform-$argument-oci | sed -n '/frt/{s/.*"\(.*\)".*/\1/p;q;}'
end
#description "fr home-ops-kubernetes will reconcile the source home-ops-kubernetes"
function fr 
    set argument $argv[1]
    flux reconcile source git $argument
end
# description "flux reload helmrelease - executes suspend and resume on a given helmrelease | args: release and namespace"
function frh 
    set helmrelease $argv[1]
    set namespace $argv[2]
    flux suspend hr $helmrelease -n $namespace
    flux resume hr $helmrelease -n $namespace
end
#  description "flux reload kustomization - executes suspend and resume on a given kustomization. | args: kustomization and namespace"
function frk
    set ks $argv[1]
    set namespace $argv[2]
    flux suspend hr $ks -n $namespace
    flux resume hr $ks -n $namespace
end

alias fho "flux reconcile source git home-ops && flux reconcile ks cluster && flux reconcile ks cluster-apps"