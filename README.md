O S3 Bucket guarda o state file do Terraform (terraform.tfstate).

O DynamoDB Table faz o locking — impede que dois terraform apply rodem ao mesmo tempo no mesmo estado (evita corrupção).

---

1. Criando bucket S3

```
aws s3api create-bucket \
  --bucket poc-atlantis-terraform \
  --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1
```

- Aplicar versionamento e criptografia no bucket:

```
aws s3api put-bucket-versioning --bucket poc-atlantis-terraform --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket poc-atlantis-terraform --server-side-encryption-configuration \
'{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

```

2. Criando tabela no DynamodDB para lock do terraform

```
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

Configurando o infracost:

https://github.com/infracost/infracost


Passo a passo pra obter o INFRACOST_API_KEY

1️⃣ Acesse o site oficial:
👉 https://www.infracost.io/

2️⃣ Clique em “Sign Up”

Pode entrar com GitHub, GitLab, Google ou e-mail.

3️⃣ Após logar, acesse o painel:
👉 https://dashboard.infracost.io/

4️⃣ No menu lateral, vá em “API Keys”

Clique em “Create API key”

Dê um nome (ex: neura-minas-poc)

Ele vai gerar algo como:

```
ic_12345abcdeFGHIJKLMN

```

5️⃣ Copie essa chave e vá pro seu repositório GitHub →
Settings → Secrets and variables → Actions → New repository secret

6️⃣ Crie um novo Secret:

Name: INFRACOST_API_KEY
Value: ic_12345abcdeFGHIJKLMN

---

<<<<<<< HEAD
=======
Crie um arquivo docker-compose.yml simples com o Atlantis configurado.

📁 Estrutura:

poc-atlantis/
├── docker-compose.yml
└── atlantis-data/

---

NGROK:

Forwarding https://pellucid-uncavalier-latricia.ngrok-free.dev -> http://localhost:4141


