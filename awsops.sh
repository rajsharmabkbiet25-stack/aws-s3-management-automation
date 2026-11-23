#!/bin/bash

# Load project modules
source utils/logging.sh
source modules/s3_management.sh

# Main menu
while true; do
    echo
    echo "======================================"
    echo "       AWS S3 MANAGEMENT TOOL"
    echo "======================================"
    echo "1. List S3 buckets"
    echo "2. Check bucket"
    echo "3. Create bucket"
    echo "4. Upload file"
    echo "5. Download file"
    echo "6. List bucket objects"
    echo "7. Get object metadata"
    echo "8. Generate bucket report"
    echo "9. Check versioning"
    echo "10. Enable versioning"
    echo "11. Check encryption"
    echo "12. Check lifecycle configuration"
    echo "13. Apply lifecycle configuration"
    echo "14. Check public access block"
    echo "15. Enable public access block"
    echo "16. Check bucket policy"
    echo "17. Check bucket policy status"
    echo "18. Delete object"
    echo "19. Restore object"
    echo "20. Delete bucket"
    echo "0. Exit"
    echo "======================================"

    read -rp "Enter your choice: " CHOICE

    case "$CHOICE" in
        1)
            list_buckets
            ;;
        2)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_bucket "$BUCKET_NAME"
            ;;
        3)
            read -rp "Enter bucket name: " BUCKET_NAME
            read -rp "Enter region [ap-south-1]: " REGION
            REGION=${REGION:-ap-south-1}
            create_bucket "$BUCKET_NAME" "$REGION"
            ;;
        4)
            read -rp "Enter local file path: " FILE_PATH
            read -rp "Enter bucket name: " BUCKET_NAME
            upload_file "$FILE_PATH" "$BUCKET_NAME"
            ;;
        5)
            read -rp "Enter S3 object path: " S3_PATH
            read -rp "Enter local destination path: " LOCAL_PATH
            download_file "$S3_PATH" "$LOCAL_PATH"
            ;;
        6)
            read -rp "Enter bucket name: " BUCKET_NAME
            read -rp "Enter prefix (optional): " PREFIX
            read -rp "Enter extension filter (optional, e.g. .txt): " EXTENSION
            list_objects "$BUCKET_NAME" "$PREFIX" "$EXTENSION"
            ;;
        7)
            read -rp "Enter bucket name: " BUCKET_NAME
            read -rp "Enter object key: " OBJECT_KEY
            get_object_metadata "$BUCKET_NAME" "$OBJECT_KEY"
            ;;
        8)
            read -rp "Enter bucket name: " BUCKET_NAME
            get_bucket_info "$BUCKET_NAME"
            ;;
        9)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_versioning "$BUCKET_NAME"
            ;;
        10)
            read -rp "Enter bucket name: " BUCKET_NAME
            enable_versioning "$BUCKET_NAME"
            ;;
        11)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_encryption "$BUCKET_NAME"
            ;;
        12)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_lifecycle "$BUCKET_NAME"
            ;;
        13)
            read -rp "Enter bucket name: " BUCKET_NAME
            read -rp "Enter lifecycle JSON file path [config/lifecycle.json]: " CONFIG_FILE
            CONFIG_FILE=${CONFIG_FILE:-config/lifecycle.json}
            set_lifecycle "$BUCKET_NAME" "$CONFIG_FILE"
            ;;
        14)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_public_access_block "$BUCKET_NAME"
            ;;
        15)
            read -rp "Enter bucket name: " BUCKET_NAME
            enable_public_access_block "$BUCKET_NAME"
            ;;
        16)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_bucket_policy "$BUCKET_NAME"
            ;;
        17)
            read -rp "Enter bucket name: " BUCKET_NAME
            check_bucket_policy_status "$BUCKET_NAME"
            ;;
        18)
            read -rp "Enter bucket name: " BUCKET_NAME
            read -rp "Enter object key: " OBJECT_KEY
            delete_object "$BUCKET_NAME" "$OBJECT_KEY"
            ;;
        19)
            read -rp "Enter bucket name: " BUCKET_NAME
            read -rp "Enter object key: " OBJECT_KEY
            read -rp "Enter delete marker version ID: " VERSION_ID
            restore_object "$BUCKET_NAME" "$OBJECT_KEY" "$VERSION_ID"
            ;;
        20)
            read -rp "Enter bucket name: " BUCKET_NAME
            delete_bucket "$BUCKET_NAME"
            ;;
        0)
            echo "Exiting AWS S3 Management Tool"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    read -rp "Press Enter to continue..."
done
