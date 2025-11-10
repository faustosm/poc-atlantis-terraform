#!/bin/sh
set -e

ATL_USER="atlantis"
ATL_GROUP="atlantis"
ATL_HOME="/home/atlantis"
ATL_DIR="${ATL_HOME}/.atlantis"

echo "[startup] fixing perms..."
mkdir -p "${ATL_DIR}"

# Ajusta donos/permissões dos binds (sem falhar se não existirem)
chown -R "${ATL_USER}:${ATL_GROUP}" "${ATL_HOME}" || true
find "${ATL_HOME}" -type d -exec chmod 775 {} \; || true
find "${ATL_HOME}" -type f -exec chmod 664 {} \; || true

echo "[startup] git safe.directory..."
# Marca diretórios do Atlantis como "seguros" p/ evitar 'dubious ownership'
git config --global --add safe.directory "${ATL_DIR}" || true
git config --global --add safe.directory "${ATL_DIR}/repos" || true

# Limpa workdirs antigos (opcional)
if [ "${CLEAN_WORKDIR}" = "1" ]; then
  echo "[startup] cleaning old workdirs..."
  rm -rf "${ATL_DIR}/repos"/* 2>/dev/null || true
fi

echo "[startup] starting atlantis..."
# Rodando como root mesmo (P0C/local) para evitar problemas de permissão
exec atlantis server --config /etc/atlantis/config.yaml
