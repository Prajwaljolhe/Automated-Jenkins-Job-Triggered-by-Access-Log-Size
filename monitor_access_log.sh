#!/bin/bash

LOG_FILE="/var/log/httpd/access_log"

# Production threshold = 1 GB
THRESHOLD=$((1024 * 1024 * 1024))

JENKINS_URL="http://localhost:8080"
JENKINS_JOB="log-upload-to-s3"

CREDENTIAL_FILE="/root/.jenkins_monitor_credentials"

LOG_FILE_MONITOR="/var/log/access_log_monitor.log"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    echo "$(timestamp) - $1" >> "$LOG_FILE_MONITOR"
}

log "Checking $LOG_FILE"

if [ ! -f "$LOG_FILE" ]; then
    log "ERROR: Log file does not exist"
    exit 1
fi

SIZE=$(stat -c%s "$LOG_FILE")

log "Current size: ${SIZE} bytes"

if [ "$SIZE" -ge "$THRESHOLD" ]; then

    log "WARNING: Log exceeded threshold"

    if [ ! -f "$CREDENTIAL_FILE" ]; then
        log "ERROR: Jenkins credential file not found"
        exit 1
    fi

    source "$CREDENTIAL_FILE"

    log "Triggering Jenkins job"

    HTTP_CODE=$(curl -s \
        -o /dev/null \
        -w "%{http_code}" \
        -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        -H "Jenkins-Crumb:${CRUMB}" \
        -X POST \
        --data "json={}" \
        "${JENKINS_URL}/job/${JENKINS_JOB}/build")

    if [ "$HTTP_CODE" = "201" ]; then
        log "Jenkins job triggered successfully. HTTP ${HTTP_CODE}"
    else
        log "ERROR: Jenkins trigger failed. HTTP ${HTTP_CODE}"
        exit 1
    fi

else

    log "Log below threshold. No action required."

fi
