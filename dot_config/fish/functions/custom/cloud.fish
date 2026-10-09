# Pulumi Aliases

function pl
    pulumi $argv
end

function plp
    pulumi preview --color always $argv
end

function plup
    pulumi up $argv
end

function plupy
    pulumi up -y $argv
end

function pld
    pulumi destroy $argv
end

function pls
    pulumi stack $argv
end

function plss
    pulumi stack select $argv
end

function plso
    pulumi stack output $argv
end

function plsoj
    pulumi stack output -j $argv
end

function plsos
    pulumi stack output --show-secrets $argv
end

function plsosj
    pulumi stack output --show-secrets -j $argv
end

function plcs
    pulumi config --show-secrets $argv
end

function plcsj
    pulumi config --show-secrets -j $argv | jq
end

function plcset
    pulumi config set $argv
end

function plcget
    pulumi config get $argv
end

function plgetp
    pulumi config get --path $argv
end

function plcgetpd
    pulumi config get --path $argv | base64 -D
end

function plias
    alias | grep "^pl"
end

function aksup
    az aks get-versions --location westeurope --output table
end

set -gx AZURE_KEYVAULT_AUTH_VIA_CLI true

function pok
    set filename $argv[1]
    pulumi stack output kubeconfig --show-secrets >>$HOME/.kube/$filename.yaml
end

function plazure
    echo Logging In into Azure Blob Storage
    sops -i -d login.sh; and ./login.sh; and sops -i -e login.sh
end

function fwip
    curl ifconfig.me | awk '{print $1"/32"}' | pbcopy
end

alias ipfw fwip

# Python
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
pyenv init - | source
