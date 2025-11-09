# Dockerfile
FROM ghcr.io/runatlantis/atlantis:v0.27.3

# Ajuste de UID e permissões para evitar "permission denied"
USER root

# Cria e garante permissões corretas
RUN mkdir -p /home/atlantis/.atlantis /etc/atlantis && \
    chown -R 1000:1000 /home/atlantis /etc/atlantis

# Copia o config.yaml (fixo no caminho que o Atlantis espera)
COPY atlantis/config.yaml /etc/atlantis/config.yaml

# Volta para o usuário padrão (seguro)
USER atlantis

# Inicia o servidor Atlantis
ENTRYPOINT ["atlantis"]
CMD ["server", "--config", "/etc/atlantis/config.yaml"]
