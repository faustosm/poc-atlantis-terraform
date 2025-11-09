# Dockerfile
FROM ghcr.io/runatlantis/atlantis:v0.27.3

# Vamos usar /bin/sh do próprio container (alpine-based) e sem sudo
USER root

# Entrypoint que corrige permissões e inicia o atlantis
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Mantemos user root no entrypoint e depois "troco" para o usuário atlantis via su-exec (já existe na imagem)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
