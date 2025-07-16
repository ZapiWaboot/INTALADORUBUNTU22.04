#!/bin/bash
echo "🚀 Instalador ZapiWaBoot (Ubuntu 22.04+)"

# =========== ATUALIZAÇÃO DO SISTEMA ===========
echo "🔄 Atualizando o sistema antes de tudo..."
sudo apt update && sudo apt upgrade -y

# =============== PROMPTS ===============
read -p "Domínio FRONTEND (ex: app.ex.com): " FRONTEND_DOMAIN
read -p "Domínio BACKEND (ex: api.ex.com): " BACKEND_DOMAIN

read -p "Nome do banco [zapiwaboot]: " DB_NAME
DB_NAME=${DB_NAME:-zapiwaboot}
read -p "Usuário do banco [zapiuser]: " DB_USER
DB_USER=${DB_USER:-zapiuser}
read -s -p "Senha do banco: " DB_PASS && echo

read -p "GitHub usuário: " GH_USER
read -s -p "GitHub token (senha): " GH_TOKEN && echo

APP="zapiwaboot"; DEPLOY="deploy"; BD_PORT=8080
BASE="/home/$DEPLOY/$APP"; FRONT="$BASE/frontend/build"

# =========== DEPENDÊNCIAS ===========
echo "📦 Instalando pacotes necessários..."
sudo apt-get install -y curl wget unzip git \
 libgbm-dev fontconfig locales gconf-service libasound2 \
 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 \
 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
 libxss1 libxtst6 ca-certificates fonts-liberation \
 libappindicator1 libnss3 lsb-release xdg-utils \
 build-essential nginx postgresql postgresql-contrib \
 redis-server certbot python3-certbot-nginx ufw fail2ban

sudo systemctl enable --now fail2ban

# =========== FIREWALL ===========
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow OpenSSH
sudo ufw allow 22
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# =========== CRIA USUÁRIO DEPLOY ===========
if ! id "$DEPLOY" &>/dev/null; then
  sudo adduser --disabled-password --gecos "" "$DEPLOY"
fi
sudo mkdir -p "/home/$DEPLOY"
sudo chown "$DEPLOY:$DEPLOY" "/home/$DEPLOY"

# =========== CLONA O REPOSITÓRIO ===========
cd "/home/$DEPLOY"
sudo -u "$DEPLOY" git clone \
"https://$GH_USER:$GH_TOKEN@github.com/ZapiWaboot/INTALADORUBUNTU22.04.git" "$APP"

sudo chown -R "$DEPLOY:$DEPLOY" "$BASE"
sudo find "$BASE" -type d -exec chmod 775 {} \;
sudo find "$BASE" -type f -exec chmod 664 {} \;

# =========== POSTGRES ===========
sudo -u postgres psql <<SQL
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
SQL

# =========== NODE, NVM, PM2, BACKEND/FRONTEND ===========
sudo -u "$DEPLOY" bash <<EOF
export NVM_DIR="/home/$DEPLOY/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source "\$NVM_DIR/nvm.sh"
nvm install 20 && nvm use 20
npm install -g pm2

# Backend
cd "$BASE/backend"
cp .env.example .env
sed -i "s/DB_USER=.*/DB_USER=$DB_USER/" .env
sed -i "s/DB_PASS=.*/DB_PASS=$DB_PASS/" .env
sed -i "s/DB_NAME=.*/DB_NAME=$DB_NAME/" .env
sed -i "s|PROD_FRONTEND_URL=.*|PROD_FRONTEND_URL=https://$FRONTEND_DOMAIN|" .env
npm install
npm run build
npx sequelize db:migrate
pm2 start dist/server.js --name backend --max-memory-restart 400M
pm2 save

# Frontend
cd "$BASE/frontend"
cp .env.example .env
sed -i "s|REACT_APP_BACKEND_URL=.*|REACT_APP_BACKEND_URL=https://$BACKEND_DOMAIN/api|" .env
npm install
npm run build
pm2 start server.js --name frontend --max-memory-restart 400M
pm2 save
EOF

# =========== NGINX ===========
sudo tee /etc/nginx/sites-available/backend.conf <<NGINX
server {
  server_name $BACKEND_DOMAIN;
  location / {
    proxy_pass http://127.0.0.1:$BD_PORT;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
NGINX

sudo tee /etc/nginx/sites-available/frontend.conf <<NGINX
server {
  server_name $FRONTEND_DOMAIN;
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/backend.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/frontend.conf /etc/nginx/sites-enabled/
sudo sed -i 's|client_max_body_size .*|client_max_body_size 20M;|' /etc/nginx/nginx.conf
sudo nginx -t && sudo systemctl restart nginx

# =========== SSL ===========
sudo certbot --nginx -d "$FRONTEND_DOMAIN" -d "$BACKEND_DOMAIN" \
 --non-interactive --agree-tos -m admin@$FRONTEND_DOMAIN
sudo systemctl enable certbot.timer

# =========== FINAL ===========
echo -e "\n✅ INSTALAÇÃO COMPLETA!"
echo "Frontend: https://$FRONTEND_DOMAIN"
echo "Backend:  https://$BACKEND_DOMAIN"
echo "Usuário deploy: $DEPLOY"
echo "Banco: $DB_NAME com usuário $DB_USER"
echo "Use: pm2 list"
