#!/bin/sh

set -e
set -o pipefail

export SSL_CERT_FILE="/userdata/certs/ca-certificates.crt"

LEGO_HOME="${LEGO_HOME:-/userdata/lego}"
LEGO_ENV_FILE="${LEGO_HOME}/.env.cf"

set -a
source "${LEGO_HOME}/.env"
set +a

LEGO="${LEGO_HOME}/bin/lego"
LOG_FILE="${LEGO_PATH}/logs/last.log"
LEGO_LOG_FILE="${LEGO_PATH}/logs/lego.log"
CERT_FILE="${LEGO_PATH}/certificates/${LEGO_CERT_NAME}"
DEPLOY_HOOK="${LEGO_HOME}/scripts/lego-deploy.sh"

mkdir -p "$(dirname "${LOG_FILE}")"

print() {
    echo "$@" | tee -a "${LOG_FILE}"
}

get_mtime() {
    date -r "$1" +%s 2>/dev/null || echo "0"
}

# Truncate the existing log files
echo -n > "${LOG_FILE}"
echo -n > "${LEGO_LOG_FILE}"

print <<EOF_START
=== Lego Certificate Renewal ===
Started: $(date)

EOF_START

# Get the current modification time on the cert.
# We'll check it again after the renew to see if anything changed.
MTIME_BEFORE=$(get_mtime "$CERT_FILE")

print "Running Lego renewal..."
if "$LEGO" run --env-file "${LEGO_ENV_FILE}" --deploy-hook "$DEPLOY_HOOK" 2>&1 | tee -a "$LEGO_LOG_FILE"; then
    LEGO_EXIT=0
else
    LEGO_EXIT=$?
fi

print ""
print "Lego exit code: $LEGO_EXIT"

MTIME_AFTER=$(get_mtime "$CERT_FILE")

print "Certificate mtime before: $MTIME_BEFORE"
print "Certificate mtime after: $MTIME_AFTER"

if [ "$LEGO_EXIT" -eq 0 ] && [ "$MTIME_AFTER" -gt "$MTIME_BEFORE" ]; then
    print "$(date): Renewal successful, rebooting..."

    # Reboot if successful
    if reboot; then
        exit 0
    else
        print "ERROR: Failed to reboot"
        exit 1
    fi
else
    if [ "$LEGO_EXIT" -ne 0 ]; then
        print "Lego renewal failed"
    else
        print "No renewal needed"
    fi
    print "Ended: $(date)"
    exit 0
fi
