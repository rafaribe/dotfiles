# On-demand personal secrets. Values live age-encrypted in
# ~/.config/secrets/personal.env.age (KEY=value lines), copied there as
# ciphertext and decrypted only when a function asks for a key.
# Add or rotate a value from a machine that has the age identity:
#   age -d -i ~/.config/chezmoi/key.txt ~/.config/secrets/personal.env.age > /tmp/p.env
#   $EDITOR /tmp/p.env
#   age -r age13c3lp878r5pt8lagcmewv6djmqac576gussyhwgv2h3a0nw9k5dq4p8erj -a -o (chezmoi source-path)/dot_config/secrets/personal.env.age /tmp/p.env
#   rm -P /tmp/p.env

set -g PERSONAL_SECRETS ~/.config/secrets/personal.env.age
set -g PERSONAL_AGE_IDENTITY ~/.config/chezmoi/key.txt

function secret --description "Print personal secrets by key: secret KEY [KEY...]"
    if test (count $argv) -eq 0
        echo "usage: secret KEY [KEY...]" >&2
        return 2
    end
    if not test -f $PERSONAL_AGE_IDENTITY
        echo "secret: no age identity at $PERSONAL_AGE_IDENTITY" >&2
        return 1
    end
    set -l lines (age -d -i $PERSONAL_AGE_IDENTITY $PERSONAL_SECRETS)
    or begin
        echo "secret: could not decrypt $PERSONAL_SECRETS" >&2
        return 1
    end
    set -l missing 0
    for key in $argv
        set -l match (string match -r -- "^$key=(.*)\$" $lines)
        if test (count $match) -lt 2
            echo "secret: $key not found" >&2
            set missing 1
            continue
        end
        echo $match[2]
    end
    return $missing
end

function load_tokens --description "Export GITHUB_TOKEN and GITLAB_TOKEN"
    set -l values (secret GITHUB_TOKEN GITLAB_TOKEN); or return 1
    set -gx GITHUB_TOKEN $values[1]
    set -gx GITLAB_TOKEN $values[2]
end

function load_minio --description "Export MinIO S3 credentials"
    set -l values (secret AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL_S3); or return 1
    set -gx AWS_ACCESS_KEY_ID $values[1]
    set -gx AWS_SECRET_ACCESS_KEY $values[2]
    set -gx AWS_ENDPOINT_URL_S3 $values[3]
end

function totp --description "Copy the email password + current TOTP to the clipboard"
    set -l values (secret EMAIL_PASSWORD EMAIL_TOTP_SECRET); or return 1
    set -l otp (oathtool --totp -b $values[2])
    or begin
        echo "totp: oathtool failed (brew install oath-toolkit)" >&2
        return 1
    end
    printf '%s%s' $values[1] $otp | pbcopy
    echo "TOTP code copied to clipboard"
end

function plrafaribe --description "Log in to Pulumi as rafaribe"
    set -l token (secret PULUMI_ACCESS_TOKEN); or return 1
    set -lx PULUMI_ACCESS_TOKEN $token
    pulumi logout
    pulumi login
end
