# TOTP for Email

function totp
    set -x BW_ITEM_ID 03100a1b-786e-46c2-9138-ae57013c9920
    set -x PASS (bw get password $BW_ITEM_ID)
    set -x OTP (totp-keychain get bribeiro@pf)
    echo -n "$PASS$OTP" | tr -d "\n" | pbcopy
    echo "TOTP code copied to clipboard"
end
## Pulumi Logins
function plpersonal
    echo "Logging In as Neoception Personal"
    set -x PULUMI_ACCESS_TOKEN (bw get password pulumi_personal_token)
    pulumi logout; pulumi login
end

function plproducts
    echo "Logging In as Neoception Products"
    set -x PULUMI_ACCESS_TOKEN (bw get password pulumi_products_token)
    pulumi logout; pulumi login
end

function plrafaribe
    echo "Logging In as rafaribe"
    set -x PULUMI_ACCESS_TOKEN (bw get password pulumi_rafaribe_token)
    pulumi logout; pulumi login
end

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
  pulumi stack output kubeconfig --show-secrets >> $HOME/.kube/$filename.yaml
end
