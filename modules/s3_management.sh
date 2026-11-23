#!/bin/bash

source utils/logging.sh

upload_file() {
    local FILE_PATH=$1
    local BUCKET_NAME=$2

    if [ ! -f "$FILE_PATH" ]; then
        log_message "ERROR: File does not exist: $FILE_PATH"
        return 1
    fi

    log_message "Starting upload: $FILE_PATH"

    if aws s3 cp "$FILE_PATH" "s3://$BUCKET_NAME/"; then
        log_message "SUCCESS: Uploaded $FILE_PATH to $BUCKET_NAME"
    else
        log_message "ERROR: Upload failed for $FILE_PATH"
        return 1
    fi
}

download_file() {
    local S3_PATH=$1
    local LOCAL_PATH=$2

    log_message "Starting download from $S3_PATH"

    if aws s3 cp "$S3_PATH" "$LOCAL_PATH"; then
        log_message "SUCCESS: Downloaded $S3_PATH to $LOCAL_PATH"
    else
        log_message "ERROR: Download failed for $S3_PATH"
        return 1
    fi
}

list_buckets() {
	log_message "Listing s3 buckets"

	if aws s3 ls
	then
		log_message "SUCCESS: Bucket listing completed"
	else
		log_message "ERROR: Unable to list buckets"
		return 1
	fi
}

check_bucket() {
	local BUCKET_NAME=$1

	if [ -z "$BUCKET_NAME" ]
	then
		log_message "ERROR: Bucket name is required"
		return -1
	fi

	if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null
	then
		log_message "SUCCESS: Bucket $BUCKET_NAME exists and is accessible"
	else
		log_message "ERROR: Bucket $BUCKET_NAME does not exist or is not accessible"
		return 1
	fi
}



create_bucket() {
    local BUCKET_NAME=$1
    local REGION=${2:-ap-south-1}

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        log_message "Bucket already exists or is accessible: $BUCKET_NAME"
        return 1
    fi

    log_message "Creating bucket: $BUCKET_NAME in $REGION"

    if [ "$REGION" = "us-east-1" ]; then
        if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"; then
            log_message "SUCCESS: Bucket created: $BUCKET_NAME"
        else
            log_message "ERROR: Bucket creation failed: $BUCKET_NAME"
            return 1
        fi
    else
        if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"; then
            log_message "SUCCESS: Bucket created: $BUCKET_NAME"
        else
            log_message "ERROR: Bucket creation failed: $BUCKET_NAME"
            return 1
        fi
    fi
}






delete_bucket() {
    local BUCKET_NAME=$1

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    read -r -p "Are you sure you want to delete bucket $BUCKET_NAME? (yes/no): " CONFIRMATION

    if [ "$CONFIRMATION" != "yes" ]; then
        log_message "Bucket deletion cancelled"
        return 1
    fi

    log_message "Deleting bucket: $BUCKET_NAME"

    if aws s3 rb "s3://$BUCKET_NAME"; then
        log_message "SUCCESS: Bucket deleted: $BUCKET_NAME"
    else
        log_message "ERROR: Bucket deletion failed: $BUCKET_NAME"
        return 1
    fi
}






enable_versioning() {
    local BUCKET_NAME=$1

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Enabling versioning for $BUCKET_NAME"

    if aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled; then

        log_message "SUCCESS: Versioning enabled for $BUCKET_NAME"
    else
        log_message "ERROR: Failed to enable versioning"
        return 1
    fi
}


check_versioning() {

	local bucket_name=$1

	if [ -z "$bucket_name" ]
	then
		log_message "ERROR: Bucket name is required"
		return 1
	fi

	local status

	status=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --query 'Status' --output text)

	if [ "$status" = "Enabled" ]
	then
		log_message "SUCCES: Versioning is enabled for $bucket_name"
	else
		log_message "WARNING: Versioning is not enabled for $bucket_name"
		return 1
	fi

}





check_encryption() {
    local BUCKET_NAME=$1

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    local ENCRYPTION

    ENCRYPTION=$(aws s3api get-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' \
        --output text)

    if [ "$ENCRYPTION" = "AES256" ]; then
        log_message "SUCCESS: SSE-S3 encryption is enabled for $BUCKET_NAME"
    elif [ "$ENCRYPTION" = "aws:kms" ]; then
        log_message "SUCCESS: SSE-KMS encryption is enabled for $BUCKET_NAME"
    else
        log_message "WARNING: Unknown or missing encryption configuration for $BUCKET_NAME"
        return 1
    fi
}




get_bucket_info() {
    local BUCKET_NAME=$1
    local TIMESTAMP
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")

    local REPORT_FILE="reports/s3_report_${TIMESTAMP}.txt"

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Generating report for $BUCKET_NAME"

    local REGION
    local VERSIONING
    local ENCRYPTION

    if ! REGION=$(aws s3api get-bucket-location \
        --bucket "$BUCKET_NAME" \
        --query 'LocationConstraint' \
        --output text); then
        log_message "ERROR: Could not retrieve bucket region"
        return 1
    fi

    if ! VERSIONING=$(aws s3api get-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --output json); then
        log_message "ERROR: Could not retrieve versioning status"
        return 1
    fi

    if ! ENCRYPTION=$(aws s3api get-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --output json); then
        log_message "ERROR: Could not retrieve encryption configuration"
        return 1
    fi

    {
        echo "========== S3 BUCKET REPORT =========="
        echo "Generated: $(date)"
        echo "Bucket Name: $BUCKET_NAME"
        echo "Region: $REGION"
        echo "Versioning: $VERSIONING"
        echo "Encryption: $ENCRYPTION"
        echo "======================================"
    } > "$REPORT_FILE"

    log_message "SUCCESS: Report saved to $REPORT_FILE"
    cat "$REPORT_FILE"
}















delete_object() {
    local BUCKET_NAME=$1
    local OBJECT_KEY=$2

    if [ -z "$BUCKET_NAME" ] || [ -z "$OBJECT_KEY" ]; then
        log_message "ERROR: Bucket name and object key are required"
        return 1
    fi

    read -r -p "Delete $OBJECT_KEY from $BUCKET_NAME? (yes/no): " CONFIRMATION

    if [ "$CONFIRMATION" != "yes" ]; then
        log_message "Object deletion cancelled"
        return 1
    fi

    log_message "Deleting object $OBJECT_KEY from $BUCKET_NAME"

    if aws s3 rm "s3://$BUCKET_NAME/$OBJECT_KEY"; then
        log_message "SUCCESS: Object deletion requested for $OBJECT_KEY"
    else
        log_message "ERROR: Object deletion failed for $OBJECT_KEY"
        return 1
    fi
}

restore_object() {
    local BUCKET_NAME=$1
    local OBJECT_KEY=$2
    local DELETE_MARKER_ID=$3

    if [ -z "$BUCKET_NAME" ] || [ -z "$OBJECT_KEY" ] || [ -z "$DELETE_MARKER_ID" ]; then
        log_message "ERROR: Bucket, object key and delete marker ID are required"
        return 1
    fi

    read -r -p "Restore $OBJECT_KEY by removing its delete marker? (yes/no): " CONFIRMATION

    if [ "$CONFIRMATION" != "yes" ]; then
        log_message "Object restoration cancelled"
        return 1
    fi

    log_message "Restoring $OBJECT_KEY in bucket $BUCKET_NAME"

    if aws s3api delete-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --version-id "$DELETE_MARKER_ID"; then

        log_message "SUCCESS: Delete marker removed for $OBJECT_KEY"
    else
        log_message "ERROR: Could not restore $OBJECT_KEY"
        return 1
    fi
}

list_objects() {
    local BUCKET_NAME=$1
    local PREFIX=$2
    local EXTENSION=$3

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Listing objects in bucket: $BUCKET_NAME"

    local OBJECTS

    if ! OBJECTS=$(aws s3api list-objects-v2 \
        --bucket "$BUCKET_NAME" \
        --prefix "$PREFIX" \
        --query 'Contents[*].[Key,Size,LastModified]' \
        --output json); then

        log_message "ERROR: Failed to retrieve objects"
        return 1
    fi

    if [ "$OBJECTS" = "None" ] || [ "$OBJECTS" = "null" ] || [ "$OBJECTS" = "[]" ]; then
        log_message "INFO: No objects found"
        return 0
    fi

    if [ -n "$EXTENSION" ]; then
        OBJECTS=$(echo "$OBJECTS" | jq -r --arg EXT "$EXTENSION" \
            '.[] | select(.[0] | endswith($EXT)) | @tsv')
    else
        OBJECTS=$(echo "$OBJECTS" | jq -r '.[] | @tsv')
    fi

    if [ -z "$OBJECTS" ]; then
        log_message "INFO: No matching objects found"
        return 0
    fi


    count=$(echo "$OBJECTS" | wc -l)
    toal_size=$(echo "$OBJECTS" | awk -F '\t' '{ total += $2 } END { print total }')  

    while IFS=$'\t' read -r key size last_modified
    do
        human_size=$(numfmt --to=iec "$size")

        printf "%-35s %-10s %s\n" "$key" "$human_size" "$last_modified"
    done <<< "$OBJECTS"

    echo "total count $count"
    echo "Total size: $(numfmt --to=iec "$toal_size")"
   
}


get_object_metadata() {
    local BUCKET_NAME=$1
    local OBJECT_KEY=$2

    if [ -z "$BUCKET_NAME" ] || [ -z "$OBJECT_KEY" ]; then
        log_message "ERROR: Bucket name and object key are required"
        return 1
    fi

    log_message "Retrieving metadata for $OBJECT_KEY"

    local METADATA

    if ! METADATA=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --query '[ContentLength, LastModified, ContentType, ServerSideEncryption, VersionId, StorageClass]' \
        --output text); then

        log_message "ERROR: Failed to retrieve object metadata"
        return 1
    fi

    local SIZE LASTMODIFIED CONTENTTYPE ENCRYPTION VERSION STORAGE_CLASS

    read -r SIZE LASTMODIFIED CONTENTTYPE ENCRYPTION VERSION STORAGE_CLASS<<< "$METADATA"

    if [ "$STORAGE_CLASS" = "None" ] || [ -z "$STORAGE_CLASS" ]; then
        STORAGE_CLASS="STANDARD"
    fi

    echo "========== OBJECT METADATA =========="
    echo "Bucket: $BUCKET_NAME"
    echo "Object: $OBJECT_KEY"
    echo "Size: $(numfmt --to=iec "$SIZE")"
    echo "Last Modified: $LASTMODIFIED"
    echo "Content Type: $CONTENTTYPE"
    echo "Encryption: $ENCRYPTION"
    echo "Version ID: $VERSION"
    echo "Storage Class: ${STORAGE_CLASS:-STANDARD}"
    echo "====================================="
}


check_lifecycle() {

    local BUCKET_NAME=$1
    
    if [ -z "$BUCKET_NAME" ]
    then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Checking lifecycle configuration for $BUCKET_NAME"

    local lifecycle

    if ! LIFECYCLE=$(aws s3api get-bucket-lifecycle-configuration \
                    --bucket "$BUCKET_NAME" \
                    --output json )
    then

        log_message "ERROR: Failed to retrive lifecycle configuration"
        return 1
    fi

    echo "$LIFECYCLE" | jq .
}

set_lifecycle() {
    local BUCKET_NAME=$1
    local CONFIG_FILE=$2

    # Validate arguments
    if [ -z "$BUCKET_NAME" ] || [ -z "$CONFIG_FILE" ]; then
        log_message "ERROR: Bucket name and configuration file are required"
        return 1
    fi

    # Check whether configuration file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "ERROR: Configuration file not found: $CONFIG_FILE"
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$CONFIG_FILE"; then
        log_message "ERROR: Invalid JSON configuration"
        return 1
    fi

    log_message "Applying lifecycle configuration to $BUCKET_NAME"

    # Apply lifecycle configuration
    if aws s3api put-bucket-lifecycle-configuration \
        --bucket "$BUCKET_NAME" \
        --lifecycle-configuration "file://$CONFIG_FILE" \
        --no-cli-pager; then

        log_message "SUCCESS: Lifecycle configuration applied to $BUCKET_NAME"
    else
        log_message "ERROR: Failed to apply lifecycle configuration"
        return 1
    fi
}


check_lifecycle() {
    local BUCKET_NAME=$1

    # Validate bucket name
    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Checking lifecycle configuration for $BUCKET_NAME"

    local LIFECYCLE

    # Retrieve lifecycle configuration
    if ! LIFECYCLE=$(aws s3api get-bucket-lifecycle-configuration \
        --bucket "$BUCKET_NAME" \
        --output json \
        --no-cli-pager 2>&1); then

        # Handle bucket without lifecycle configuration
        if [[ "$LIFECYCLE" == *"NoSuchLifecycleConfiguration"* ]]; then
            log_message "INFO: No lifecycle configuration exists for $BUCKET_NAME"
            return 0
        fi

        log_message "ERROR: Failed to retrieve lifecycle configuration"
        echo "$LIFECYCLE"
        return 1
    fi

    # Format and display JSON
    echo "$LIFECYCLE" | jq .

    log_message "SUCCESS: Lifecycle configuration retrieved"
}


enable_public_access_block() {
    local BUCKET_NAME=$1

    # Validate bucket name
    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Enabling public access block for $BUCKET_NAME"

    # Apply all four public access restrictions
    if aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true' \
        --no-cli-pager; then

        log_message "SUCCESS: Public access block enabled for $BUCKET_NAME"
    else
        log_message "ERROR: Failed to enable public access block"
        return 1
    fi
}



check_public_access_block() {
    local BUCKET_NAME=$1

    # Validate bucket name
    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Checking public access block for $BUCKET_NAME"

    local CONFIG

    # Retrieve public access block configuration
    if ! CONFIG=$(aws s3api get-public-access-block \
        --bucket "$BUCKET_NAME" \
        --query 'PublicAccessBlockConfiguration' \
        --output json \
        --no-cli-pager); then

        log_message "ERROR: Failed to retrieve public access block configuration"
        return 1
    fi

    # Display configuration
    echo "$CONFIG" | jq .

    # Check whether all four settings are enabled
    if echo "$CONFIG" | jq -e '
        .BlockPublicAcls == true and
        .IgnorePublicAcls == true and
        .BlockPublicPolicy == true and
        .RestrictPublicBuckets == true
    ' > /dev/null; then

        log_message "SUCCESS: All public access restrictions are enabled"
    else
        log_message "WARNING: One or more public access restrictions are disabled"
        return 1
    fi
}


check_bucket_policy() {
    local BUCKET_NAME=$1

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Checking bucket policy for $BUCKET_NAME"

    local POLICY

    if ! POLICY=$(aws s3api get-bucket-policy \
        --bucket "$BUCKET_NAME" \
        --query 'Policy' \
        --output text \
        --no-cli-pager 2>&1); then

        if [[ "$POLICY" == *"NoSuchBucketPolicy"* ]]; then
            log_message "INFO: No bucket policy is configured"
            return 0
        fi

        log_message "ERROR: Failed to retrieve bucket policy"
        echo "$POLICY"
        return 1
    fi

    echo "$POLICY" | jq .

    local POLICY_STATUS

    if ! POLICY_STATUS=$(aws s3api get-bucket-policy-status \
        --bucket "$BUCKET_NAME" \
        --query 'PolicyStatus.IsPublic' \
        --output text \
        --no-cli-pager); then

        log_message "ERROR: Failed to retrieve bucket policy status"
        return 1
    fi

    if [ "$POLICY_STATUS" = "True" ]; then
        log_message "WARNING: Bucket policy allows public access"
    else
        log_message "SUCCESS: Bucket policy is not public"
    fi
}

check_bucket_policy_status() {
    local BUCKET_NAME=$1

    if [ -z "$BUCKET_NAME" ]; then
        log_message "ERROR: Bucket name is required"
        return 1
    fi

    log_message "Checking bucket policy status for $BUCKET_NAME"

    local STATUS

    if ! STATUS=$(aws s3api get-bucket-policy-status \
        --bucket "$BUCKET_NAME" \
        --query 'PolicyStatus.IsPublic' \
        --output text \
        --no-cli-pager 2>&1); then

        if [[ "$STATUS" == *"NoSuchBucketPolicy"* ]]; then
            log_message "INFO: No bucket policy exists; no policy-based public access is configured"
            return 0
        fi

        log_message "ERROR: Failed to retrieve bucket policy status"
        echo "$STATUS"
        return 1
    fi

    if [ "$STATUS" = "True" ]; then
        log_message "WARNING: Bucket policy allows public access"
        return 1
    else
        log_message "SUCCESS: Bucket policy does not allow public access"
    fi
}