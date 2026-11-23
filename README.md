# AWS S3 Management Automation

A Bash-based AWS operations tool that automates common Amazon S3 management tasks using the AWS CLI.

The project provides a menu-driven interface for managing S3 buckets, objects, security configurations, lifecycle policies, and object versioning.

## Features

### Bucket Management
- List S3 buckets
- Check bucket existence and accessibility
- Create S3 buckets
- Delete empty buckets with confirmation

### Object Management
- Upload files to S3
- Download objects from S3
- List objects with optional prefix and extension filters
- Retrieve object metadata
- Delete objects with confirmation
- Restore objects by removing delete markers in versioned buckets

### Security Management
- Enable S3 Block Public Access
- Verify all four public access block settings
- Inspect bucket policies
- Check whether a bucket policy allows public access
- Check server-side encryption configuration (SSE-S3 and SSE-KMS)

### Versioning and Lifecycle Management
- Enable and check bucket versioning
- Configure S3 lifecycle rules using JSON
- Inspect lifecycle configurations
- Generate bucket configuration reports

### Logging and Reporting
- Timestamped operation logs
- Error and success messages
- Timestamped S3 bucket reports

## Project Structure

```text
aws-s3-management-automation/
├── awsops.sh
├── README.md
├── .gitignore
├── config/
│   └── lifecycle.json
├── modules/
│   └── s3_management.sh
├── utils/
│   ├── logging.sh
│   └── validation.sh
├── scripts/
├── logs/
└── reports/
```

## Technologies Used

- Bash
- AWS CLI
- Amazon S3
- jq
- Linux
- Git and GitHub

## Prerequisites

- Linux environment (tested on Amazon Linux 2023)
- AWS CLI v2
- Bash 5.x
- jq
- AWS account
- IAM permissions for the required S3 operations

## AWS Authentication

The project uses the EC2 instance IAM role for AWS authentication.

No hardcoded AWS access keys or secret keys are required.

Verify the active AWS identity:

```bash
aws sts get-caller-identity
```

## Installation

Clone the repository:

```bash
git clone git@github.com:rajsharmabkbiet25-stack/aws-s3-management-automation.git
```

Enter the project directory:

```bash
cd aws-s3-management-automation
```

Make the main application executable:

```bash
chmod +x awsops.sh
```

Configure AWS CLI authentication and the desired default region.

## Configuration

Update the lifecycle configuration in:

```text
config/lifecycle.json
```

The example lifecycle rule manages objects under the `logs/` prefix.

It includes:
- Transition to STANDARD_IA after 30 days
- Expiration after 365 days
- Noncurrent version expiration after 30 days

Review lifecycle rules carefully before applying them to a bucket containing important data.

## Usage

Start the application:

```bash
./awsops.sh
```

The interactive menu provides operations for:

1. Listing and creating buckets
2. Uploading and downloading objects
3. Listing objects and retrieving metadata
4. Checking bucket configuration
5. Managing versioning and encryption
6. Applying lifecycle configurations
7. Managing public access restrictions
8. Inspecting bucket policies
9. Deleting and restoring objects

The application prompts for the required bucket names, object keys, and file paths.

## Testing

Run the module test script:

```bash
./test_s3.sh
```

Check shell syntax:

```bash
find . -type f -name "*.sh" -print0 |
while IFS= read -r -d '' FILE; do
    bash -n "$FILE" || exit 1
done
```

## Security Considerations

- Uses an IAM role instead of hardcoded credentials.
- Enables all four S3 Block Public Access settings.
- Uses server-side encryption.
- Supports bucket versioning.
- Requires confirmation for destructive operations.
- Avoids automatically deleting non-empty buckets.
- Keeps credentials and generated files out of Git.

## Learning Outcomes

This project demonstrates practical experience with:

- Bash scripting and functions
- Conditional statements, loops, and input handling
- AWS CLI automation
- S3 bucket and object operations
- JSON processing with jq
- Error handling and logging
- IAM roles and cloud security
- Git and GitHub project management

## Future Improvements

- Add automated backup and recovery workflows.
- Add CloudWatch monitoring and alerting.
- Add automated bucket compliance checks.
- Add scheduled reporting.
- Add unit and integration tests.

## Author

Raj Sharma

GitHub: https://github.com/rajsharmabkbiet25-stack