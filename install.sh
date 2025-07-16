#!/bin/bash

clear
echo "🚀 Iniciando instalação do ZapiWaBoot no Ubuntu 22.04..."

# === COLETA INTERATIVA ===
read -p "🌐 Domínio do FRONTEND (ex: app.seudominio.com): " FRONTEND_DOMAIN
read -p "🌐 Domínio do BACKEND (ex: api.seudominio.com): " BACKEND_DOMAIN

read -p "📦 Nome do banco de dados [zapiwaboot]: " DB_NAME
DB_NAME=${DB_NAME:-zapiwaboot}

read -p "👤 Usuário do banco [zapiuser]: " DB_USER
DB_USER=${DB_USER:-zapiuser}

read -s -p "🔑 Senha do banco: " DB_PASS
echo

# === CRIA USUÁRIO E DIRETÓRIO ===
useradd -m deploy || true
mkdir -p /home/deploy
cd /home/deploy

# === ATUALIZA SISTEMA ===
echo "🔄 Atualizando servidor..."
apt update && apt upgrade -y
apt install -y curl wget unzip git build-essential

# === INSTALA DEPENDÊNCIAS ===
apt install -y libgbm-dev fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 \
libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 \
libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 \
libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 \
libnss3 lsb-release xdg-utils

# === FAIL2BAN ===
apt install -y fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable --now fail2ban

# === FIREWALL ===
ufw default allow outgoing
ufw default deny incoming
ufw allow ssh
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

# === NODEJS 20 ===
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt install -y nodejs
npm install -g pm2

# === REDIS ===
apt install -y redis
systemctl enable --now redis-server

# === POSTGRES ===
apt install -y postgresql postgresql-contrib
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# === NGINX ===
apt install -y nginx
rm -f /etc/nginx/sites-enabled/default

# === CERTBOT ===
snap install core && snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# === CLONE DO PROJETO ===
cd /home/deploy
git clone https://github.com/ZapiWaboot/CODIGOZAPIWABOOT2025.git zapiwaboot
cd zapiwaboot

# === BACKEND ===
cd backend
cp .env.example .env

sed -i "s|DB_USER=.*|DB_USER=$DB_USER|" .env
sed -i "s|DB_PASS=.*|DB_PASS=$DB_PASS|" .env
sed -i "s|DB_NAME=.*|DB_NAME=$DB_NAME|" .env
sed -i "s|PROD_FRONTEND_URL=.*|PROD_FRONTEND_URL=https://$FRONTEND_DOMAIN|" .env

npm install
npm run build
npx sequelize db:migrate
pm2 start dist/server.js --name backend

# === FRONTEND ===
cd ../frontend
cp .env.example .env
sed -i "s|REACT_APP_BACKEND_URL=.*|REACT_APP_BACKEND_URL=https://$BACKEND_DOMAIN/api|" .env
npm install
npm run build

# === NGINX CONFIG ===
tee /etc/nginx/sites-available/backend.conf > /dev/null <<EOF
server {
  server_name $BACKEND_DOMAIN;
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
EOF

tee /etc/nginx/sites-available/frontend.conf > /dev/null <<EOF
server {
  server_name $FRONTEND_DOMAIN;
  root /home/deploy/zapiwaboot/frontend/build;
  index index.html;

  location / {
    try_files \$uri /index.html;
  }
}
EOF

ln -s /etc/nginx/sites-available/backend.conf /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/frontend.conf /etc/nginx/sites-enabled/

# === SSL ===
certbot --nginx -d "$FRONTEND_DOMAIN" -d "$BACKEND_DOMAIN" --non-interactive --agree-tos -m admin@$FRONTEND_DOMAIN
systemctl reload nginx

# === PM2 SETUP ===
pm2 startup systemd
pm2 save

# === PERMISSÕES ===
chown -R deploy:deploy /home/deploy
find /home/deploy -type d -exec chmod 775 {} \;
find /home/deploy -type f -exec chmod 664 {} \;

# === FIM ===
echo ""
echo "✅ INSTALAÇÃO COMPLETA!"
echo "🌍 Frontend: https://$FRONTEND_DOMAIN"
echo "🔗 Backend: https://$BACKEND_DOMAIN"
echo "📦 Banco: $DB_NAME com usuário $DB_USER"
echo "🧠 PM2 status: pm2 list"
echo "🔐 SSL ativo"
