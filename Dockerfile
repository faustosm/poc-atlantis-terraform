# Dockerfile
FROM ghcr.io/runatlantis/atlantis:v0.27.3

USER root

# Define explicitamente o diretório home do usuário atlantis
ENV HOME=/home/atlantis
ENV USER=atlantis
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis

# Cria as pastas necessárias com as permissões corretas
RUN mkdir -p ${ATLANTIS_DATA_DIR}/repos /etc/atlantis && \
    chown -R 1000:1000 /home/atlantis /etc/atlantis && \
    chmod -R 755 /home/atlantis /etc/atlantis

# Copia o arquivo de configuração do Atlantis
COPY atlantis/config.yaml /etc/atlantis/config.yaml

USER atlantis
WORKDIR /home/atlantis

ENTRYPOINT ["atlantis"]
CMD ["server", "--config", "/etc/atlantis/config.yaml"]
