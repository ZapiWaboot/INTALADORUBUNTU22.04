##  🚀 Instalador ZapiWaBoot (Whaticket) – Para Ubuntu 22.04
- Desenvolvido por ZapiWaBoot — Sistema de atendimento WhatsApp.

Este repositório contém um instalador automatizado para o sistema ZapiWaBoot (Whaticket), com configuração completa para uso em ambientes de produção. Inclui:

- PostgreSQL
- Redis
- Node.js
- Nginx
- Certbot com SSL automático
- PM2 para gerenciamento
- Multiempresa

---

## 📌 Pré-requisitos

- VPS com Ubuntu 22.04 LTS
- Domínios apontando para a VPS (A record)
- Domínio frontEnd (app.seusite.com.br)
- Domínio Backedn (api.seusite.com.br)
- Conta no GitHub com token pessoal gerado (para clonar repositórios privados)





## 🛠️ Etapas da instalação

Primeiro, execute os seguintes comandos para atualizar e instalar as dependências necessárias:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip git
```



##  01 - COLOCAR O COMANDO ABAIXO

```bash
sudo apt install -y git && \
git clone https://github.com/ZapiWaboot/INTALADORUBUNTU22.04 && \
cd INTALADORUBUNTU22.04 && \
sudo chmod -R 777 install_primaria && \
sudo ./install_primaria
```

## PARA A SEGUNDA INSTALAÇÃO  UTILIZE O SEGUINTE COMANDO:

```bash
cd /home && sudo apt install -y git && git clone https://github.com/ZapiWaboot/INTALADORUBUNTU22.04 instalador && sudo chmod -R 777 ./instalador && cd ./instalador && sudo ./install_primaria
```



## 02 - DIGITE O COMANDO ABAIXO

Quando solicitado, digite o número "0".



## 03 - Insira a Senha para o Usuário Deploy e Banco de Dados
Não utilize caracteres especiais. Exemplo: senha1234




## 04 - INSIRA O LINK DO GITHUB DO WHATICKET QUE DESEJA INSTALAR
Informe o link do repositório GitHub do Whaticket que você deseja instalar:

Exemplo: https://github.com/github/nomedoseucodigoqueestahospedadonogithub.git




## 05 - INFORME UM NOME PARA A INSTÂNCIA/EMPRESA
Não utilize espaços ou caracteres especiais, apenas letras minúsculas. Exemplo: nomedaempresa




## 06 - INFORME A QUANTIDADE DE CONEXÕES/WHATS QUE SUA EMPRESA PODERÁ CADASTRAR
Defina a quantidade de conexões ou Whats que sua empresa poderá cadastrar. Exemplo: 9999




## 07 - INFORME A QUANTIDADE DE USUÁRIOS/ATENDENTES QUE SUA EMPRESA PODERÁ CADASTRAR
Defina a quantidade de usuários/atendentes que sua empresa poderá cadastrar. Exemplo: 9999




## 08 - DIGITE O DOMÍNIO DO FRONTEND/PAINEL PARA SUA EMPRESA
Informe o domínio para o frontend/painel de administração da sua empresa. Exemplo: app.seudominio.com.br




## 09 - DIGITE O DOMÍNIO DO BACKEND/API PARA SUA EMPRESA
Informe o domínio para o backend da sua empresa. Exemplo: api.seudominio.com.br




## 10 - DIGITE A PORTA DO FRONTEND PARA SUA EMPRESA
Informe a porta do frontend que sua empresa utilizará (Exemplo: de 3000 a 3999). Exemplo: 3000




## 11 - DIGITE A PORTA DO BACKEND PARA SUA EMPRESA
Informe a porta do backend que sua empresa utilizará (Exemplo: de 4000 a 4999). Exemplo: 4000




## 12 - DIGITE A PORTA DO REDIS/AGENDAMENTO NSG PARA SUA EMPRESA
Informe a porta do Redis ou agendamento NSG para sua empresa. Exemplo:5000




## 13 - COLOQUE O NOME DO SEU USUÁRIO E SENHA
Informe o nome de usuário e a senha do seu GitHub, Exemplo: seu-usuario-github




## 14 - COLOQUE O TOKEN GERADO NO SEU GITHUB
Informe o token gerado no seu GitHub, Exemplo: ghp_AAn6usdfds125LIEINdfsdikxds84dasdu4a




