FROM ghcr.io/runatlantis/atlantis:v0.27.3

# Rodamos como root para evitar qualquer bloqueio de permissão
USER root

ENV HOME=/home/atlantis
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis
ENV ATLANTIS_CONFIG_FILE=/etc/atlantis/config.yaml
ENV ATLANTIS_LOG_LEVEL=debug

# Prepara dirs base
RUN mkdir -p ${ATLANTIS_DATA_DIR} /etc/atlantis /repos \
 && chmod -R 775 /home/atlantis /etc/atlantis /repos

# Copia o config do servidor (com allow_custom_workflows habilitado p/ seu repo)
COPY atlantis/config.yaml /etc/atlantis/config.yaml
RUN chmod 644 /etc/atlantis/config.yaml

# Start script: corrige permissões, marca safe.directory e inicia o Atlantis
CMD sh -lc '\
  echo "[startup] fixing perms..." && \
  mkdir -p ${ATLANTIS_DATA_DIR} /repos && \
  chmod -R u+rwX,g+rwX ${ATLANTIS_DATA_DIR} /repos || true && \
  echo "[startup] git safe.directory..." && \
  git config --global --add safe.directory "*" || true && \
  git config --global --add safe.directory /home/atlantis/.atlantis/repos/faustosm/poc-atlantis-terraform/5/default || true && \
  echo "[startup] starting atlantis..." && \
  exec atlantis server --config /etc/atlantis/config.yaml --log-level ${ATLANTIS_LOG_LEVEL}'
