#!/bin/bash

source utils/logging.sh
source modules/s3_management.sh

BUCKET_NAME="raj-awsops-797693"

echo "========== CHECK BUCKET POLICY STATUS =========="

check_bucket_policy_status "$BUCKET_NAME"
