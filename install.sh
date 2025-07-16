#!/bin/bash

# Script de instalação do ZapiWaBoot (Whaticket) via CODIGOZAPIWABOOT2025
# Compatível com Ubuntu 22.04+

echo "🚀 Iniciando instalação automatizada do ZapiWaBoot..."

# === DADOS DO USUÁRIO ===
read -p "🌐 Domínio do FRONTEND (ex: app.seudominio.com): " FRONTEND_DOMAIN
read -p "🌐 Domínio do BACKEND (ex: api.seudominio.com): " BACKEND_DOMAIN

read -p "📦 Nome do banco de dados [zapiwaboot]: " DB_NAME
DB_NAME=${DB_NAME:-zapiwaboot}

read -p "👤 Usuário do banco [zapiuser]: " DB_USER
DB_USER=${DB_USER:-zapiuser}

read -s -p "🔑 Senha do banco: " DB_PASS
echo

read -p "👤 GitHub usuário (para clonar o repositório): " GITHUB_USER
read -s -p "🔑 GitHub token (acesso pessoal): " GITHUB_TOKEN
echo

APP_NAME="zapiwaboot"
BACKEND_PORT=8080
DEPLOY_USER="deploy"
PROJECT_DIR="/home/$DEPLOY_USER/$APP_NAME"
FRONTEND_DIR="$PROJECT_DIR/frontend/build"

# === DEPENDÊNCIAS ===
echo "📦 Instalando pacotes do sistema..."
apt update && apt upgrade -y
apt install -y git curl build-essential nginx postgresql postgresql-contrib redis certbot python3-certbot-nginx ufw sudo

# === CRIANDO USUÁRIO DEPLOY ===
if ! id "$DEPLOY_USER" &>/dev/null; then
  echo "👤 Criando usuário '$DEPLOY_USER'..."
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
fi

mkdir -p "/home/$DEPLOY_USER"
chown "$DEPLOY_USER":"$DEPLOY_USER" "/home/$DEPLOY_USER"

# === CLONANDO PROJETO AUTENTICADO ===
echo "📥 Clonando repositório ZapiWaBoot com autenticação GitHub..."
cd "/home/$DEPLOY_USER"
REPO_URL="https://$GITHUB_USER:$GITHUB_TOKEN@github.com/ZapiWaboot/CODIGOZAPIWABOOT2025.git"
sudo -u "$DEPLOY_USER" git clone "$REPO_URL" "$APP_NAME"

# === AJUSTANDO PERMISSÕES ===
echo "🔐 Ajustando permissões..."
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$PROJECT_DIR"
find "$PROJECT_DIR" -type d -exec chmod 775 {} \;
find "$PROJECT_DIR" -type f -exec chmod 664 {} \;

# === CONFIGURANDO BANCO DE DADOS ===
echo "🐘 Criando banco e usuário PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

# === EXECUTANDO SETUP COMO DEPLOY ===
su - "$DEPLOY_USER" <<EOF
# Node e PM2 via NVM
export NVM_DIR="/home/$DEPLOY_USER/.nvm"
source "\$NVM_DIR/nvm.sh" || true

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source "\$NVM_DIR/nvm.sh"
nvm install 20
nvm use 20
npm install -g pm2

# Backend
cd "$PROJECT_DIR/backend"
cp .env.example .env
sed -i "s/DB_USER=.*/DB_USER=$DB_USER/" .env
sed -i "s/DB_PASS=.*/DB_PASS=$DB_PASS/" .env
sed -i "s/DB_NAME=.*/DB_NAME=$DB_NAME/" .env
sed -i "s|PROD_FRONTEND_URL=.*|PROD_FRONTEND_URL=https://$FRONTEND_DOMAIN|" .env

npm install
npm run build
npx sequelize db:migrate
pm2 start dist/server.js --name zapi-backend

# Frontend
cd "$PROJECT_DIR/frontend"
cp .env.example .env
sed -i "s|REACT_APP_BACKEND_URL=.*|REACT_APP_BACKEND_URL=https://$BACKEND_DOMAIN/api|" .env
npm install
npm run build
EOF

# === CONFIGURANDO NGINX ===
echo "🌐 Configurando NGINX..."
tee /etc/nginx/sites-available/zapiwaboot <<EOF
server {
    listen 80;
    server_name $FRONTEND_DOMAIN;

    root $FRONTEND_DIR;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }
}

server {
    listen 80;
    server_name $BACKEND_DOMAIN;

    location /api/ {
        proxy_pass http://localhost:$BACKEND_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/zapiwaboot /etc/nginx/sites-enabled
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# === SSL ===
echo "🔐 Ativando HTTPS com Certbot..."
certbot --nginx -d "$FRONTEND_DOMAIN" -d "$BACKEND_DOMAIN" --non-interactive --agree-tos -m admin@$FRONTEND_DOMAIN
systemctl enable certbot.timer

# === FIREWALL ===
echo "🛡️ Ativando UFW..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# === FINAL ===
echo ""
echo "✅ Instalação concluída com sucesso!"
echo "🌍 Frontend: https://$FRONTEND_DOMAIN"
echo "🔗 Backend:  https://$BACKEND_DOMAIN/api"
echo "📦 Banco: $DB_NAME (usuário: $DB_USER)"
echo "🧠 PM2 status: su - deploy -c 'pm2 list'"
echo "🔐 SSL com auto-renovação habilitado."
echo ""
exit 0
