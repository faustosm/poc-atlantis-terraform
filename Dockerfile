FROM ghcr.io/runatlantis/atlantis:v0.27.3

USER root

# Diretórios e variáveis
ENV HOME=/home/atlantis
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis
ENV ATLANTIS_CONFIG_FILE=/etc/atlantis/config.yaml

# Cria estrutura e corrige permissões
RUN mkdir -p ${ATLANTIS_DATA_DIR} /etc/atlantis && \
    chown -R 1000:1000 /home/atlantis /etc/atlantis && \
    chmod -R 755 /home/atlantis /etc/atlantis

# Copia config fixo direto para a imagem
RUN echo '# atlantis/config.yaml\nrepos:\n  - id: /.*/\n    allow_repo_config: true\n    allow_custom_workflows: true' > /etc/atlantis/config.yaml && \
    chown 1000:1000 /etc/atlantis/config.yaml && chmod 644 /etc/atlantis/config.yaml

USER atlantis
WORKDIR /home/atlantis

# Força explicitamente o uso do arquivo
ENTRYPOINT ["atlantis"]
CMD ["server", "--config", "/etc/atlantis/config.yaml"]
