function unlock_bw_if_locked
    if test -z BW_SESSION
        echo 'bw locked - unlocking into a new session'
        export BW_SESSION="$(bw unlock --raw)"
    end
end

function reload_bitwarden
    bw logout
    rm ~/.bw_session
    omf reload
end

function load_tokens
    set -l GITLAB_UUID "ba81e9c2-b042-4aab-b98f-ae57013c9920"
    set -l GITHUB_UUID "109b214e-de5b-4366-a30a-ae57013c9920"
    unlock_bw_if_locked
    set -gx GITHUB_TOKEN "$(bw get item $GITHUB_UUID | jq -r '.fields[] | select(.name == "GITHUB_TOKEN").value')"
    set -gx GITLAB_TOKEN "$(bw get item $GITLAB_UUID | jq -r '.fields[] | select(.name == "GITLAB_TOKEN").value')"
end

