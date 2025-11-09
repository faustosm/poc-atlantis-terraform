#!/bin/bash
set -e

echo "🧹 Limpando containers antigos do Atlantis..."
docker compose down -v || true

echo "📂 Garantindo estrutura de diretórios..."
mkdir -p atlantis-data atlantis/repos

echo "🔒 Corrigindo permissões dos volumes..."
sudo chown -R 65534:65534 ./atlantis-data || true
sudo chmod -R 775 ./atlantis-data

echo "📄 Verificando arquivo de configuração..."
if [ ! -f "./atlantis/config.yaml" ]; then
  echo "⚠️  Criando config.yaml padrão..."
  mkdir -p atlantis
  cat > ./atlantis/config.yaml <<EOF
repos:
  - id: /.*/
    allow_repo_config: true
    allow_custom_workflows: true
    allowed_overrides: [workflow]
EOF
fi

echo "🚀 Subindo o container Atlantis..."
docker compose up -d --force-recreate

echo "✅ Atlantis iniciado com sucesso!"
echo "Acesse: http://localhost:4141 ou via ngrok configurado."
