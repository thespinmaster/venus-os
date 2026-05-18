#!/bin/bash

set -eu

SERVICE_NAME="opkg-manager-service"
SERVICE_DIR="${VE_ROOT_DIR:-}/service/${SERVICE_NAME}"
PID_FILE="/var/run/opkg-manager-service.pid"

if [[ -d "${SERVICE_DIR}" ]]; then
  svc -d "${SERVICE_DIR}" >/dev/null 2>&1 || true
fi

if [[ ! -f "${PID_FILE}" ]]; then
  exit 0
fi

pid="$(cat "${PID_FILE}")"
rm -f "${PID_FILE}"

if [[ -z "${pid}" ]]; then
  exit 0
fi

if kill -0 "${pid}" 2>/dev/null; then
  kill "${pid}" 2>/dev/null || true
fi
