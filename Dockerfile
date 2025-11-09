FROM ghcr.io/runatlantis/atlantis:v0.27.3

# Vamos usar root só na build para preparar permissões
USER root

# Definir variáveis de ambiente importantes
ENV HOME=/home/atlantis
ENV ATLANTIS_CONFIG_FILE=/etc/atlantis/config.yaml
ENV ATLANTIS_DATA_DIR=/home/atlantis/.atlantis

# Criar diretórios e corrigir permissões
RUN mkdir -p ${ATLANTIS_DATA_DIR} /etc/atlantis /repos && \
    chown -R 1000:1000 /home/atlantis /etc/atlantis /repos && \
    chmod -R 755 /home/atlantis /etc/atlantis /repos

# Copiar o config.yaml (de fora do container)
COPY atlantis/config.yaml /etc/atlantis/config.yaml

# Ajustar permissões do arquivo
RUN chown 1000:1000 /etc/atlantis/config.yaml && chmod 644 /etc/atlantis/config.yaml

# Voltar ao usuário padrão
USER atlantis
WORKDIR /home/atlantis

# Executar o Atlantis com o config já configurado
ENTRYPOINT ["atlantis"]
CMD ["server", "--config", "/etc/atlantis/config.yaml"]
