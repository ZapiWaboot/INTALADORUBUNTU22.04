#!/bin/bash
#
# Imprimir arte do banner.

#######################################
# Imprima um tabuleiro.
# Globais:
#   BG_BROWN
#   NC
#   WHITE
#   CYAN_LIGHT
#   RED
#   GREEN
#   YELLOW
# Argumentos:
# Nenhum
#######################################
print_banner() {

  clear

  printf "\n\n"

  printf "\n"

  printf "${GREEN}";
  printf "    ╔════════════════════════════════════════════════════════════╗\n";
  printf "    ║                        ZAPI WABOOT                         ║\n";
  printf "    ║       SISTEMA DE MULTIATENDIMENTO PARA WHATSAPP            ║\n";
  printf "    ╚════════════════════════════════════════════════════════════╝\n";
  printf "${NC}";

  printf "\n"

  printf "${YELLOW}";
  printf "    ┌────────────────────────────────────────────────────────────┐\n";
  printf "    │                    AVISO DE LEGALIDADE                     │\n";
  printf "    └────────────────────────────────────────────────────────────┘\n";
  printf "${NC}";
  
  printf "${WHITE}";
  printf "    Este sistema é de propriedade exclusiva do ZAPI WABOOT,\n";
  printf "    protegido por direitos autorais e licenças de uso.\n\n";
  printf "    A reprodução, distribuição ou modificação não autorizada\n";
  printf "    são proibidas por lei.\n\n";
  printf "    Use o instalador para instalação do ZAPI WABOOT\n\n";
  printf "    Ao prosseguir, você concorda com os termos de uso e com\n";
  printf "    a utilização legal do sistema.\n";
  printf "${NC}";

  printf "\n"

  printf "${GREEN}";
  printf "    ┌────────────────────────────────────────────────────────────┐\n";
  printf "    │                         SUPORTE                            │\n";
  printf "    │                    +55 11 99023-9898                       │\n";
  printf "    └────────────────────────────────────────────────────────────┘\n";
  printf "${NC}";

  printf "\n"
}