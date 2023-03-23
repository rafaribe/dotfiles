# Update Kubeconfig
# Takes all yaml files under ~/.kube/ and adds them together in a combined config file.
function ukf
    set -l backup_dir ~/.kube/backup
    set -l date (date -u +'%Y-%m-%dT%H:%M:%SZ')
    mkdir -p $backup_dir
    echo $date
    mv ~/.kube/config $backup_dir/config-$date
    if test -n ~/.kube/*.yaml
        set -x KUBECONFIG (echo ~/.kube/*.yaml | tr ' ' ':')
        kubectl config view --merge --flatten > ~/.kube/config
        echo "KUBECONFIG updated"
    else
        echo "No YAML files found in ~/.kube/"
    end
end
