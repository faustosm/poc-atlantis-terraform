FROM ghcr.io/runatlantis/atlantis:v0.27.3

USER root

ENV HOME=/home/atlantis
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis
ENV ATLANTIS_CONFIG_FILE=/etc/atlantis/config.yaml

RUN mkdir -p ${ATLANTIS_DATA_DIR} /etc/atlantis && \
    chown -R 1000:1000 /home/atlantis /etc/atlantis && \
    chmod -R 755 /home/atlantis /etc/atlantis

# ✅ Corrigido: grava YAML real
RUN cat <<'EOF' > /etc/atlantis/config.yaml
repos:
  - id: /.*/
    allow_repo_config: true
    allow_custom_workflows: true
EOF

RUN chown 1000:1000 /etc/atlantis/config.yaml && chmod 644 /etc/atlantis/config.yaml

USER atlantis
WORKDIR /home/atlantis

ENTRYPOINT ["atlantis"]
CMD ["server", "--config", "/etc/atlantis/config.yaml"]
