# Define the path to the session file
set session_file ~/.bw_session
# Check if the session file exists and load it if it does
if test -f $session_file
    set -gx BW_SESSION (cat $session_file)
else
    # Set up Bitwarden variables and log in
    set -gx BW_CLIENTSECRET "<bw_client_secret>"
    set -gx BW_CLIENTID "<bw_client_id>"
    set -gx BW_PASSWORD "<bw_vault_password>"
    
    bw login --apikey
    set -gx BW_SESSION (bw unlock --passwordenv BW_PASSWORD --raw)

    # Save the session to the session file
    echo $BW_SESSION > $session_file
end
