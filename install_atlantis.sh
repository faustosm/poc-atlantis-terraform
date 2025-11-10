#!/usr/bin/env bash
set -euo pipefail

# =========================
# 0) Carrega .env (se houver)
# =========================
if [[ -f ".env" ]]; then
  export $(grep -v '^\s*#' .env | grep -E '^[A-Za-z0-9_]+=' | xargs -d '\n') || true
fi

# =========================
# 1) Variáveis
# =========================
ATLANTIS_VERSION="${ATLANTIS_VERSION:-latest}"   # "latest" ou "v0.36.0"
ATLANTIS_USER="${ATLANTIS_USER:-atlantis}"
ATLANTIS_GROUP="${ATLANTIS_GROUP:-atlantis}"
ATLANTIS_HOME="${ATLANTIS_HOME:-/home/${ATLANTIS_USER}}"
ATLANTIS_DATA_DIR="${ATLANTIS_DATA_DIR:-${ATLANTIS_HOME}/.atlantis}"
ATLANTIS_ETC_DIR="${ATLANTIS_ETC_DIR:-/etc/atlantis}"
ATLANTIS_BIN="${ATLANTIS_BIN:-/usr/local/bin/atlantis}"
ATLANTIS_PORT="${ATLANTIS_PORT:-4141}"

ATLANTIS_PUBLIC_URL="${ATLANTIS_PUBLIC_URL:-}"
ATLANTIS_GH_USER="${ATLANTIS_GH_USER:-faustosm}"
PERSONAL_GITHUB_TOKEN="${PERSONAL_GITHUB_TOKEN:-}"
GITHUB_WEBHOOK_SECRET="${GITHUB_WEBHOOK_SECRET:-}"
ATLANTIS_REPO_ALLOWLIST="${ATLANTIS_REPO_ALLOWLIST:-github.com/faustosm/poc-atlantis-terraform}"
CLEAN_WORKDIR="${CLEAN_WORKDIR:-1}"

[[ -z "${ATLANTIS_PUBLIC_URL}" ]] && { echo "[ERRO] Defina ATLANTIS_PUBLIC_URL no .env"; exit 1; }
[[ -z "${PERSONAL_GITHUB_TOKEN}" || -z "${GITHUB_WEBHOOK_SECRET}" ]] && { echo "[ERRO] Defina PERSONAL_GITHUB_TOKEN e GITHUB_WEBHOOK_SECRET no .env"; exit 1; }

echo "[INFO] Usando:"
echo "  ATLANTIS_PUBLIC_URL=${ATLANTIS_PUBLIC_URL}"
echo "  ATLANTIS_GH_USER=${ATLANTIS_GH_USER}"
echo "  ATLANTIS_REPO_ALLOWLIST=${ATLANTIS_REPO_ALLOWLIST}"
echo "  CLEAN_WORKDIR=${CLEAN_WORKDIR}"

# =========================
# 2) Dependências
# =========================
echo "[STEP] Instalando dependências..."
sudo apt-get update -y
sudo apt-get install -y curl unzip git ca-certificates jq

# =========================
# 3) Usuário/dirs/perms
# =========================
echo "[STEP] Criando usuário/grupo '${ATLANTIS_USER}' (se necessário)..."
if ! id -u "${ATLANTIS_USER}" &>/dev/null; then
  sudo useradd -m -s /usr/sbin/nologin "${ATLANTIS_USER}"
fi

echo "[STEP] Criando diretórios e permissões..."
sudo mkdir -p "${ATLANTIS_DATA_DIR}" "${ATLANTIS_ETC_DIR}"
sudo chown -R "${ATLANTIS_USER}:${ATLANTIS_GROUP}" "${ATLANTIS_HOME}" || true
sudo chown -R "${ATLANTIS_USER}:${ATLANTIS_GROUP}" "${ATLANTIS_ETC_DIR}" "${ATLANTIS_DATA_DIR}"
sudo chmod 0755 "${ATLANTIS_HOME}" "${ATLANTIS_ETC_DIR}" "${ATLANTIS_DATA_DIR}"

# =========================
# 4) Baixa Atlantis (robusto)
# =========================
install_atlantis_binary() {
  local tag="$1"
  local api_url
  local ua="faustosm-install-script"

  if [[ "${tag}" == "latest" ]]; then
    api_url="https://api.github.com/repos/runatlantis/atlantis/releases/latest"
  else
    api_url="https://api.github.com/repos/runatlantis/atlantis/releases/tags/${tag}"
  fi

  echo "[STEP] Consultando assets do GitHub (${api_url})..."
  # Usa API para pegar o asset correto linux_amd64 (zip ou tar.gz)
  local json
  json="$(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "User-Agent: ${ua}" \
    "${api_url}")"

  # Se o tag foi "latest", descobrir o tag_name real para prints
  local resolved_tag
  resolved_tag="$(echo "${json}" | jq -r '.tag_name')"

  # Procura primeiro .tar.gz; se não houver, tenta .zip
  local url
  url="$(echo "${json}" | jq -r '.assets[].browser_download_url | select(test("linux_amd64.*\\.tar\\.gz$"))' | head -n1)"
  if [[ -z "${url}" || "${url}" == "null" ]]; then
    url="$(echo "${json}" | jq -r '.assets[].browser_download_url | select(test("linux_amd64.*\\.zip$"))' | head -n1)"
  fi

  if [[ -z "${url}" || "${url}" == "null" ]]; then
    echo "[ERRO] Não encontrei asset linux_amd64 (.tar.gz ou .zip) na release ${resolved_tag:-$tag}."
    echo "Assets disponíveis:"
    echo "${json}" | jq -r '.assets[].browser_download_url'
    exit 1
  fi

  echo "[STEP] Baixando Atlantis ${resolved_tag:-$tag} de:"
  echo "      ${url}"
  local tmp="/tmp/atlantis_asset"
  rm -f ${tmp}.tgz ${tmp}.zip || true
  curl -fL -o "${tmp}" "${url}"

  # Descobre extensão e extrai
  if [[ "${url}" =~ \.tar\.gz$ ]]; then
    mv "${tmp}" "${tmp}.tgz"
    sudo tar -xzf "${tmp}.tgz" -C /usr/local/bin atlantis
  elif [[ "${url}" =~ \.zip$ ]]; then
    mv "${tmp}" "${tmp}.zip"
    sudo unzip -o "${tmp}.zip" atlantis -d /usr/local/bin
  else
    echo "[ERRO] Formato de asset inesperado: ${url}"
    exit 1
  fi

  sudo chmod 0755 /usr/local/bin/atlantis
  echo "[OK] Atlantis instalado em /usr/local/bin/atlantis"
  /usr/local/bin/atlantis version || true
}

install_atlantis_binary "${ATLANTIS_VERSION}"

# =========================
# 5) config.yaml (server-side)
# =========================
echo "[STEP] Escrevendo ${ATLANTIS_ETC_DIR}/config.yaml..."
sudo tee "${ATLANTIS_ETC_DIR}/config.yaml" >/dev/null <<'YAML'
repos:
  - id: /.*/
    allow_repo_config: true
    allow_custom_workflows: true
    allowed_overrides: [workflow, apply_requirements]
YAML
sudo chown "${ATLANTIS_USER}:${ATLANTIS_GROUP}" "${ATLANTIS_ETC_DIR}/config.yaml"
sudo chmod 0644 "${ATLANTIS_ETC_DIR}/config.yaml"

# =========================
# 6) EnvironmentFile com segredos
# =========================
echo "[STEP] Escrevendo ${ATLANTIS_ETC_DIR}/atlantis.env..."
sudo tee "${ATLANTIS_ETC_DIR}/atlantis.env" >/dev/null <<ENV
ATLANTIS_PUBLIC_URL=${ATLANTIS_PUBLIC_URL}
ATLANTIS_GH_USER=${ATLANTIS_GH_USER}
PERSONAL_GITHUB_TOKEN=${PERSONAL_GITHUB_TOKEN}
GITHUB_WEBHOOK_SECRET=${GITHUB_WEBHOOK_SECRET}
ATLANTIS_REPO_ALLOWLIST=${ATLANTIS_REPO_ALLOWLIST}
CLEAN_WORKDIR=${CLEAN_WORKDIR}
ENV
sudo chown "${ATLANTIS_USER}:${ATLANTIS_GROUP}" "${ATLANTIS_ETC_DIR}/atlantis.env"
sudo chmod 0640 "${ATLANTIS_ETC_DIR}/atlantis.env"

# =========================
# 7) Pre-start: limpeza e git safe.directory
# =========================
echo "[STEP] Escrevendo /usr/local/bin/atlantis-clean.sh..."
sudo tee /usr/local/bin/atlantis-clean.sh >/dev/null <<'CLEAN'
#!/usr/bin/env bash
set -euo pipefail
# Carrega variáveis do systemd EnvironmentFile quando chamado por systemd
: "${CLEAN_WORKDIR:=0}"
: "${ATLANTIS_DATA_DIR:=/home/atlantis/.atlantis}"

if [[ "${CLEAN_WORKDIR}" == "1" ]]; then
  echo "[CLEAN] Removendo workdirs antigos em ${ATLANTIS_DATA_DIR}..."
  rm -rf "${ATLANTIS_DATA_DIR}/repos" || true
fi

# Evita "dubious ownership"
git config --global --add safe.directory "${ATLANTIS_DATA_DIR}/repos/faustosm/poc-atlantis-terraform/5/default" || true
CLEAN
sudo chmod 0755 /usr/local/bin/atlantis-clean.sh

# =========================
# 8) systemd unit
# =========================
echo "[STEP] Escrevendo /etc/systemd/system/atlantis.service..."
sudo tee /etc/systemd/system/atlantis.service >/dev/null <<SERVICE
[Unit]
Description=Atlantis Server (Terraform PR Automation)
After=network-online.target
Wants=network-online.target

[Service]
User=${ATLANTIS_USER}
Group=${ATLANTIS_GROUP}
EnvironmentFile=${ATLANTIS_ETC_DIR}/atlantis.env
Environment=ATLANTIS_HOME=${ATLANTIS_HOME}
Environment=ATLANTIS_DATA_DIR=${ATLANTIS_DATA_DIR}
WorkingDirectory=${ATLANTIS_HOME}
ExecStartPre=/usr/local/bin/atlantis-clean.sh

ExecStart=${ATLANTIS_BIN} server \
  --port ${ATLANTIS_PORT} \
  --config ${ATLANTIS_ETC_DIR}/config.yaml \
  --atlantis-url \$ATLANTIS_PUBLIC_URL \
  --gh-user \$ATLANTIS_GH_USER \
  --gh-token \$PERSONAL_GITHUB_TOKEN \
  --gh-webhook-secret \$GITHUB_WEBHOOK_SECRET \
  --repo-allowlist \$ATLANTIS_REPO_ALLOWLIST

Restart=on-failure
RestartSec=3
ReadWritePaths=${ATLANTIS_HOME} ${ATLANTIS_DATA_DIR} ${ATLANTIS_ETC_DIR}

[Install]
WantedBy=multi-user.target
SERVICE

# =========================
# 9) Permissões finais e start
# =========================
echo "[STEP] Ajustando permissões finais..."
sudo chown -R "${ATLANTIS_USER}:${ATLANTIS_GROUP}" "${ATLANTIS_HOME}" "${ATLANTIS_DATA_DIR}" "${ATLANTIS_ETC_DIR}"

echo "[STEP] Habilitando e iniciando serviço..."
sudo systemctl daemon-reload
sudo systemctl enable atlantis.service
sudo systemctl restart atlantis.service

echo
echo "=============================================================="
echo "[OK] Atlantis instalado e iniciado."
echo " - Binário: ${ATLANTIS_BIN}"
echo " - Config:  ${ATLANTIS_ETC_DIR}/config.yaml"
echo " - Env:     ${ATLANTIS_ETC_DIR}/atlantis.env"
echo " - Dados:   ${ATLANTIS_DATA_DIR}"
echo " - Porta:   ${ATLANTIS_PORT}"
echo " - URL:     ${ATLANTIS_PUBLIC_URL}"
echo
echo "Checar status/logs:"
echo "  sudo systemctl status atlantis -n 50"
echo "  journalctl -u atlantis -f"
echo "=============================================================="
