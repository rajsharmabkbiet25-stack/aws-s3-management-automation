#!/bin/bash

log_message() {
	local MESSAGE=$1
	local TIMESTAMP
	TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

	echo "[$TIMESTAMP] $MESSAGE" | tee -a logs/awsops.log

}
