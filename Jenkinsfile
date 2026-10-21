pipeline {

    agent any

    environment {
        LOG_FILE = '/var/log/httpd/access_log'
        S3_BUCKET = 'jenkins-access-log-prajwal-2026'
        S3_PREFIX = 'access-logs'
    }

    stages {

        stage('Check Log') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "CHECK LOG"
                    echo "======================================"

                    echo "Log file: ${LOG_FILE}"

                    if [ ! -f "${LOG_FILE}" ]; then
                        echo "ERROR: Log file does not exist"
                        exit 1
                    fi

                    SIZE=$(stat -c%s "${LOG_FILE}")

                    echo "Log size: ${SIZE} bytes"

                    if [ "${SIZE}" -eq 0 ]; then
                        echo "ERROR: Log file is empty"
                        exit 1
                    fi

                    ls -lh "${LOG_FILE}"

                    echo "Log check successful"
                '''
            }
        }

        stage('Upload to S3') {
            steps {

                script {

                    env.TIMESTAMP = sh(
                        script: 'date +%Y%m%d_%H%M%S',
                        returnStdout: true
                    ).trim()

                    env.LOG_NAME = sh(
                        script: 'basename "${LOG_FILE}"',
                        returnStdout: true
                    ).trim()

                    env.S3_KEY =
                        "${S3_PREFIX}/${LOG_NAME}_${TIMESTAMP}"

                    echo "S3 destination:"
                    echo "s3://${S3_BUCKET}/${S3_KEY}"
                }

                sh '''
                    set -e

                    echo "Uploading log to S3..."

                    aws s3 cp \
                    "${LOG_FILE}" \
                    "s3://${S3_BUCKET}/${S3_KEY}"

                    echo "Upload completed successfully"
                '''
            }
        }

        stage('Verify Upload') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY S3 UPLOAD"
                    echo "======================================"

                    aws s3api head-object \
                    --bucket "${S3_BUCKET}" \
                    --key "${S3_KEY}"

                    S3_SIZE=$(aws s3api head-object \
                        --bucket "${S3_BUCKET}" \
                        --key "${S3_KEY}" \
                        --query ContentLength \
                        --output text)

                    LOCAL_SIZE=$(stat -c%s "${LOG_FILE}")

                    echo "Local size: ${LOCAL_SIZE} bytes"
                    echo "S3 size:    ${S3_SIZE} bytes"

                    if [ "${S3_SIZE}" -ne "${LOCAL_SIZE}" ]; then
                        echo "ERROR: S3 size does not match local file"
                        exit 1
                    fi

                    echo "S3 verification successful"
                '''
            }
        }

        stage('Clear Log') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "CLEAR ORIGINAL LOG"
                    echo "======================================"

                    : > "${LOG_FILE}"

                    NEW_SIZE=$(stat -c%s "${LOG_FILE}")

                    echo "New log size: ${NEW_SIZE} bytes"

                    if [ "${NEW_SIZE}" -ne 0 ]; then
                        echo "ERROR: Failed to clear log"
                        exit 1
                    fi

                    echo "Log cleared successfully"
                '''
            }
        }
    }

    post {

        success {
            echo "SUCCESS: Log uploaded, verified and cleared."
        }

        failure {
            echo "FAILURE: Log upload failed."
            echo "Original log was NOT intentionally cleared."
        }
    }
}
