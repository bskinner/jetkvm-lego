#!/bin/sh
# Deploy hook for Lego - copies renewed certificates to their destination

set -e

LEGO_HOME="/userdata/lego"
LEGO_PATH="${LEGO_HOME}/.lego"

source "${LEGO_HOME}/.env"

CERT_SRC="${LEGO_PATH}/certificates/${LEGO_CERT_NAME}.crt"
KEY_SRC="${LEGO_PATH}/certificates/${LEGO_CERT_NAME}.key"
CERT_DST="/userdata/jetkvm/tls/user-defined.crt"
KEY_DST="/userdata/jetkvm/tls/user-defined.key"

mkdir -p "$(dirname "${CERT_DST}")"

cp "${CERT_SRC}" "${CERT_DST}"
cp "${KEY_SRC}" "${KEY_DST}"
