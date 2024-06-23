function load_minio
    set -l MINIO_UUID "4bac1bcd-ef9e-4a60-97b2-af3201766c37"
    set -gx AWS_ACCESS_KEY_ID "$(bw get item $MINIO_UUID | jq -r '.fields[] | select(.name == "AWS_ACCESS_KEY_ID").value')"
    set -gx AWS_SECRET_ACCESS_KEY "$(bw get item $MINIO_UUID | jq -r '.fields[] | select(.name == "AWS_SECRET_ACCESS_KEY").value')"
    set -gx AWS_ENDPOINT_URL_S3 "$(bw get item $MINIO_UUID | jq -r '.fields[] | select(.name == "AWS_ENDPOINT_URL_S3").value')"
end