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

3. Configurando o backend no Terraform:

