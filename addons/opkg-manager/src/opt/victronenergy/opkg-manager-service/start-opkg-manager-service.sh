#!/bin/bash

set -eu

SERVICE_NAME="opkg-manager-service"
SERVICE_TEMPLATE_DIR="${VE_ROOT_DIR:-}/opt/victronenergy/service/${SERVICE_NAME}"
SERVICE_DIR="${VE_ROOT_DIR:-}/service/${SERVICE_NAME}"

if [[ ! -d "${SERVICE_TEMPLATE_DIR}" ]]; then
  echo "warning: service template not found at ${SERVICE_TEMPLATE_DIR}"
  exit 0
fi

if [[ ! -d "${SERVICE_DIR}" ]]; then
  cp -R "${SERVICE_TEMPLATE_DIR}/" "${VE_ROOT_DIR:-}/service/"
fi

if [[ ! -x "${SERVICE_DIR}/run" && -x "${SERVICE_TEMPLATE_DIR}/run" ]]; then
  cp "${SERVICE_TEMPLATE_DIR}/run" "${SERVICE_DIR}/run"
  chmod +x "${SERVICE_DIR}/run"
fi

if [[ ! -d "${SERVICE_DIR}/log" ]]; then
  mkdir -p "${SERVICE_DIR}/log"
fi

if [[ ! -x "${SERVICE_DIR}/log/run" && -x "${SERVICE_TEMPLATE_DIR}/log/run" ]]; then
  cp "${SERVICE_TEMPLATE_DIR}/log/run" "${SERVICE_DIR}/log/run"
  chmod +x "${SERVICE_DIR}/log/run"
fi

# Stop legacy/manual instance that can hold the D-Bus name and cause supervise restarts.
legacy_pid="$(ps | awk '/python3 \/opt\/victronenergy\/service\/opkg-manager-service\/opkg-manager-service.py/ { print $1; exit }')"
if [[ -n "${legacy_pid}" ]]; then
  kill "${legacy_pid}" >/dev/null 2>&1 || true
fi

svc -u "${SERVICE_DIR}" >/dev/null 2>&1 || true
