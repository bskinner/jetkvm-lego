#!/bin/sh

LEGO_HOME="/userdata/lego"
CRON_HOME="/userdata/cron"

echo "Fetching CA Certificate bundle..."
mkdir -p (dirname "${LEGO_HOME}/certs/ca-certificates.crt")
wget \
    -O "${LEGO_HOME}/certs/ca-certificates.crt" \
    --no-check-certificate \
    "https://curl.se/ca/cacert.pem"

export SSL_CERT_FILE="${LEGO_HOME}/certs/ca-certificates.crt"

LEGO_VERSION="5.2.2"
LEGO_RELEASE_URL="https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_linux_armv7.tar.gz"
LEGO_RELEASE_FILE="lego_v${LEGO_VERSION}_linux_armv7.tar.gz"
LEGO_RELEASE_DEST_PATH="${LEGO_HOME}/lego_${LEGO_VERSION}"
echo "Fetching Lego v${LEGO_VERSION} binary..."

(
    mkdir "$LEGO_RELEASE_DEST_PATH"
    cd "$LEGO_RELEASE_DEST_PATH"
    wget \
        -O "$LEGO_RELEASE_FILE" \
        --no-check-certificate \
        "$LEGO_RELEASE_URL"
    tar -zxf "$LEGO_RELEASE_FILE"
)

mkdir "${LEGO_HOME}/bin"
cp "${LEGO_RELEASE_DEST_PATH}/lego" "${LEGO_HOME}/bin/lego"
rm -rf "$LEGO_RELEASE_DEST_PATH"

if [ ! -h "/etc/init.d/S22cron" ]; then
    ln -s "${LEGO_HOME}/init.d/S22cron" "/etc/init.d/S22cron"
fi

if [ ! -h "/etc/init.d/S22renew" ]; then
    ln -s "${LEGO_HOME}/init.d/S30renew" "/etc/init.d/S22renew"
fi

LEGO_RENEW_JOB="0 1 * * 0 $LEGO_HOME/scripts/lego-renew.sh"

CRONTAB="crontab -c '${CRON_HOME}' -e root"

(${CRONTAB} -l 2>/dev/null; echo "$LEGO_RENEW_JOB") | sort -u | crontab -

echo "Lego has been configured. Please reboot to complete setup."
