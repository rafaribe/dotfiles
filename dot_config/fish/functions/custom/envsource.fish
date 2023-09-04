function envsource
    for line in (cat $argv | grep -v '^#')
      set item (string split -m 1 '=' $line)
      set -gx $item[1] $item[2]
      echo "Exported key $item[1]"
    end
  end

set -x GOPATH (go env GOPATH)
set -x GOBIN (go env GOPATH)/bin
fish_add_path $GOBIN
fish_add_path $GOPATH

function sdk
  bass source ~/.sdkman/bin/sdkman-init.sh ';' sdk $argv
end