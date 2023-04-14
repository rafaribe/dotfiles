# Update Kubeconfig
# Takes all yaml files under ~/.kube/ and adds them together in a combined config file.
function ukf
    set -x backup_dir ~/.kube/backup
    set -x date (date -u +'%Y-%m-%dT%H:%M:%SZ')
    mkdir -p $backup_dir
    echo $date
    mv ~/.kube/config $backup_dir/config-$date
    set -l yaml_files (ls ~/.kube/*.yaml)
    if test -n "$yaml_files"
        set -x KUBECONFIG (echo $yaml_files | tr ' ' ':')
        kubectl config view --merge --flatten > ~/.kube/config
        echo "KUBECONFIG updated"
    else
        echo "No YAML files found in ~/.kube/"
    end
end