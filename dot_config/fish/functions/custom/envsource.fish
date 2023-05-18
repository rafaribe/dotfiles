function envsource
    for line in (cat $argv | grep -v '^#')
      set item (string split -m 1 '=' $line)
      set -gx $item[1] $item[2]
      echo "Exported key $item[1]"
    end
  end

function set_go_variables
    set go_env_output (go env)
    for line in $go_env_output
        set -l key (echo $line | awk -F'=' '{print $1}' | tr -d '"')
        set -l value (echo $line | awk -F'=' '{print $2}' | tr -d '"')
        switch $key
            case "GOPATH"
                set -gx GOPATH $value
                set -gx GOBIN $value/bin
            # Add more cases for other variables if needed
        end
    end

    fish_add_path $GOBIN
    fish_add_path $GOPATH
end

if status --is-interactive
    set_go_variables
end