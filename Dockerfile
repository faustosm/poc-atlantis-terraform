FROM ghcr.io/runatlantis/atlantis:v0.27.3

USER root

# Garante variáveis corretas
ENV HOME=/home/atlantis
ENV USER=atlantis
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis
ENV ATLANTIS_CONFIG_FILE=/etc/atlantis/config.yaml

# Garante estrutura e permissões
RUN mkdir -p ${ATLANTIS_DATA_DIR}/repos /etc/atlantis && \
    chown -R 1000:1000 /home/atlantis /etc/atlantis && \
    chmod -R 755 /home/atlantis /etc/atlantis

# Copia o config.yaml
COPY atlantis/config.yaml /etc/atlantis/config.yaml
RUN chown 1000:1000 /etc/atlantis/config.yaml && chmod 644 /etc/atlantis/config.yaml

USER atlantis
WORKDIR /home/atlantis

ENTRYPOINT ["atlantis"]
CMD ["server", "--config", "/etc/atlantis/config.yaml"]
