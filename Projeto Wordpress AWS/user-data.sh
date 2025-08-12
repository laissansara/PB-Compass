#!/bin/bash
# Ativa modo de depuração
set -x

# 1. Redirecionar saída para log
echo "Iniciando user-data em $(date)" > /var/log/user-data.log
exec > >(tee -a /var/log/user-data.log) 2>&1

# 2. Atualizar e instalar dependências
echo "Atualizando sistema e instalando dependências..."
if ! apt-get update -y || ! apt-get install -y nfs-common docker.io curl; then
    echo "FALHA na instalação de pacotes"
    exit 1
fi

# Habilitar e iniciar Docker
systemctl enable docker --now

# Instalar docker-compose atualizado
echo "Instalando docker-compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Adicionar usuário ao grupo docker (ajuste conforme AMI)
usermod -aG docker ubuntu

# 3. Montar EFS com retry
EFS_DNS_NAME="sua_efs"
EFS_MNT_POINT="/mnt/efs-data"
mkdir -p "$EFS_MNT_POINT"

echo "Montando EFS..."
max_retries=5
for ((retry=1; retry<=max_retries; retry++)); do
    if mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 "$EFS_DNS_NAME:/" "$EFS_MNT_POINT"; then
        echo "EFS montado com sucesso na tentativa $retry"
        break
    fi
    sleep 15
    echo "Tentativa $retry falhou"
done

# Verificar se montou
if ! mountpoint -q "$EFS_MNT_POINT"; then
    echo "FALHA CRÍTICA: Não foi possível montar o EFS."
    exit 1
fi

# Ajustar permissões para WordPress
echo "Ajustando permissões do EFS..."
chown -R 33:33 "$EFS_MNT_POINT"

# 4. Criar diretório do app e docker-compose.yml
APP_DIR="/app"
mkdir -p "$APP_DIR"
cat <<'EOF' > "$APP_DIR/docker-compose.yml"
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: seu RDS
      WORDPRESS_DB_USER: seu user
      WORDPRESS_DB_PASSWORD: sua senha
      WORDPRESS_DB_NAME: nome do seu banco de dados
    volumes:
      - /mnt/efs-data:/var/www/html
EOF

# 5. Subir container
cd "$APP_DIR" || exit 1
docker-compose up -d

# Verificar status
echo "Verificando containers..."
docker ps -a

echo "User-data completo em $(date)"
