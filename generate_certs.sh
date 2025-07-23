#!/bin/bash

TRACE_LOG() {
  Command_log_file="/tmp/.$(basename "${BASH_SOURCE[0]}").log"
  exec >>"${Command_log_file}" 2>&1
  exec 3>> "${Command_log_file}"
  export BASH_XTRACEFD=3 PS4='($BASH_SOURCE:$LINENO:$FUNCNAME): '
  set -x
}

LOAD_CONFIG() {
  # 載入設定檔，若不存在則終止
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CONFIG_FILE="${SCRIPT_DIR}/config"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "[ERROR] Config file not found: ${CONFIG_FILE}"
    exit 1
  fi
  # 安全載入設定
  source "${CONFIG_FILE}"
}

mk_cert_dir() {
  cd ${SCRIPT_DIR}
  mkdir -p ${SCRIPT_DIR}/${DOMAIN_NAME}
  cd ${SCRIPT_DIR}/${DOMAIN_NAME}
}

gen_ca() {
  echo "[*] Generating CA private key..."
  openssl genrsa -out "$CA_KEY" 4096

  echo "[*] Generating CA certificate..."
  openssl req -x509 -new -nodes -sha512 -days "$CA_DAYS" \
    -subj "$CA_SUBJ" \
    -key "$CA_KEY" \
    -out "$CA_CRT"
}

gen_server_csr() {
  echo "[*] Generating server private key..."
  openssl genrsa -out "$SERVER_KEY" 4096

  echo "[*] Generating server CSR..."
  openssl req -new -sha512 \
    -subj "$SERVER_SUBJ" \
    -key "$SERVER_KEY" \
    -out "$SERVER_CSR"
}

write_v3_ext() {
  echo "[*] Writing v3 extensions to $V3_EXT"
  {
    echo "authorityKeyIdentifier=keyid,issuer"
    echo "basicConstraints=CA:FALSE"
    echo "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment"
    echo "extendedKeyUsage = serverAuth"
    printf "subjectAltName = @alt_names\n\n[alt_names]\n"
    for n in "${ALT_NAMES[@]}"; do
      echo "$n"
    done
  } > "$V3_EXT"
}

sign_server_cert() {
  echo "[*] Signing server certificate with CA..."
  openssl x509 -req -sha512 -days "$SERVER_DAYS" \
    -extfile "$V3_EXT" \
    -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
    -in "$SERVER_CSR" \
    -out "$SERVER_CRT"
}

cleanup() {
  echo "[*] Cleanup: CA serial, CSR..."
  rm -f "${CA_CRT%.crt}.srl" "$SERVER_CSR"
}

# === MAIN ===

main() {
  TRACE_LOG
  LOAD_CONFIG
  mk_cert_dir
  gen_ca
  gen_server_csr
  write_v3_ext
  sign_server_cert
  cleanup
  set +x
  echo "[✔] All done."
}

# Only run if script is executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
