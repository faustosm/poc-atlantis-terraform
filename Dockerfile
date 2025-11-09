FROM ghcr.io/runatlantis/atlantis:v0.27.3

# Usamos root para evitar qualquer bloqueio de permissão em /usr/bin/git e nos volumes
USER root

ENV HOME=/home/atlantis
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis
ENV ATLANTIS_CONFIG_FILE=/etc/atlantis/config.yaml

# Prepara diretórios e permissões básicas
RUN mkdir -p ${ATLANTIS_DATA_DIR} /etc/atlantis /repos \
 && chmod -R 775 /home/atlantis /etc/atlantis /repos

# Copia o config do servidor Atlantis (com allow_custom_workflows)
COPY atlantis/config.yaml /etc/atlantis/config.yaml
RUN chmod 644 /etc/atlantis/config.yaml

# Entry-point: ajusta permissões dos volumes a cada start e sobe o server
# Sem depender de chown manual no host
CMD sh -lc '\
  echo "[startup] fixing perms..." && \
  mkdir -p ${ATLANTIS_DATA_DIR} /repos && \
  chmod -R u+rwX,g+rwX ${ATLANTIS_DATA_DIR} /repos || true && \
  echo "[startup] starting atlantis..." && \
  exec atlantis server --config /etc/atlantis/config.yaml'
