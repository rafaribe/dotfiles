function unlock_bw_if_locked
    if test -z BW_SESSION
        echo 'bw locked - unlocking into a new session'
        export BW_SESSION="$(bw unlock --raw)"
    end
end

function load_github
    unlock_bw_if_locked
  
    set -l github_pat_id $BITWARDEN_GIST_ID
    set -l github_token
    set -l github_token "$(bw get notes $github_pat_id)"
    export GITHUB_OAUTH_TOKEN="$github_token"
    export GITHUB_TOKEN="$github_token"
    export GIT_TOKEN="$github_token"
  end