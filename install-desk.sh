#!/usr/bin/env bash

# ======================================================================================================================================================== #
# wget -O- desk.linuxuniverse.com.br | bash -i
# ======================================================================================================================================================== #

MENU_VERSION="v3.2 - 11/06/2025"

export list01="cabextract chromium-codecs-ffmpeg-extra fonts-liberation gstreamer1.0-libav gstreamer1.0-plugins-ugly gstreamer1.0-vaapi liba52-0.7.4 libaribb24-0 libavcodec-extra \
net-tools netdiscover iperf arp-scan traceroute speedtest-cli whois openvpn curl dialog duf gnome-disk-utility vlc kolourpaint cpu-x \
cifs-utils samba smbclient liblchown-perl p7zip unrar lz4 rclone rsnapshot iotop \
printer-driver-escpr hplip printer-driver-all \
lm-sensors cmatrix btop inxi tree dialog filelight libreoffice libreoffice-l10n-pt-br \
libssl3 pcscd opensc xmlstarlet \
xrdp xorgxrdp freerdp2-x11 openssh-server \
adsys adsys-windows samba-ad-dc sssd-ad sssd-tools realmd adcli smb4k gdebi-core" 
# Pacotes removidos: build-essential liblchown-perl rclone rsnapshot iotop net-tools netdiscover iperf arp-scan traceroute speedtest-cli whois openvpn xmlstarlet screen qemu-system qemu-utils qemu-user qemu-kvm qemu-guest-agent libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf dnsmasq genisoimage guestfs-tools
# Motivo: ferramentas de compilação, backup, monitoramento, redes avançadas e virtualização, que não são necessárias para a maioria dos usuários comuns.

# ======================================================================================================================================================== #

function root_check0 {
  if ! [ "$EUID" -ne 0 ]; then
    clear
    echo "Não execute este script como Root! DICA: Remova o SUDO do comando ou execute-o como usuario local."; echo ""
    exit
  fi
}

function welcome0 {
  clear; echo ""; echo "Preparo do $(lsb_release -ds) by SuitIT® - $MENU_VERSION"; echo ""
  echo "Insira a senha do usuário $USER"; echo ""
  sudo echo . >/dev/null
  echo ""; echo "5"; sleep 1; echo "4"; sleep 1; echo "3"; sleep 1; echo "2"; sleep 1; echo "1"; sleep 1
}

function useless0 {
  clear; echo "Removendo pacotes e desativando servicos inuteis"; echo ""
  sudo apt purge unattended-upgrades plasma-discover-backend-snap -y
  sudo systemctl disable systemd-networkd-wait-online.service
  sudo systemctl mask systemd-networkd-wait-online.service
}

function update0 {
  clear; echo "Atualizando o sistema"; echo ""
  sudo apt update; sudo apt upgrade -y; sudo apt autoremove -y; clear

  cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.
# For more information: https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

  sudo apt-mark hold snapd
  echo "Instalando pacotes..."
  sudo apt install $list01 -y
  sync &&

  sudo -E usermod -aG docker "$USER"
}

function token0 {
  if ! [ -f /etc/.tokenok ]; then
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1-1ubuntu2.1~18.04.23_amd64.deb
    sudo dpkg -i libssl1.1_1.1.1-1ubuntu2.1~18.04.23_amd64.deb; sudo rm libssl1*.deb

    wget http://archive.ubuntu.com/ubuntu/pool/main/g/gdk-pixbuf-xlib/libgdk-pixbuf-xlib-2.0-0_2.40.2-2build4_amd64.deb
    sudo dpkg -i libgdk-pixbuf-xlib-2.0-0_2.40.2-2build4_amd64.deb; sudo rm libgdk*.deb

    wget http://archive.ubuntu.com/ubuntu/pool/universe/g/gdk-pixbuf-xlib/libgdk-pixbuf2.0-0_2.40.2-2build4_amd64.deb
    sudo dpkg -i libgdk-pixbuf2.0-0_2.40.2-2build4_amd64.deb; sudo rm libgdk*.deb

    sudo apt update; sudo apt upgrade -y
     
    cd /tmp; wget https://www.globalsign.com/en/safenet-drivers/USB/10.7/Safenet_Linux_Installer_DEB_x64.zip
    unzip Safenet_Linux_Installer_DEB_x64.zip
    sudo dpkg -i safenetauthenticationclient_10.7.77_amd64.deb
    sudo apt --fix-broken install -y

    sudo apt install libnss3-tools -y

    message0

    rm -fr ~/.pki/nssdb; mkdir -p ~/.pki/nssdb; certutil -d ~/.pki/nssdb -N -f <(echo -n "")

    cd ~; modutil -dbdir sql:.pki/nssdb/ -add "Safenet 5110" -libfile "/usr/lib/libeToken.so"

    sudo touch /etc/.tokenok
  fi
}

function bashconf0 {
  clear; echo "Configurando BASH"; echo ""
  curl -sSL https://raw.githubusercontent.com/urbancompasspony/bashrc/main/install.sh | bash
}

function timezone0 {
  sudo timedatectl set-timezone Etc/GMT+3
  sudo timedatectl set-local-rtc 1
}

function sysctl0 {
  if ! [ -f /etc/.sysctlok ]; then
    sleep 3; clear; echo "Aplicando recursos extras ao SYSCTL"
    echo -e "kernel.sysrq=1
vm.panic_on_oom=1
vm.swappiness=10
kernel.panic=5
#net.ipv4.ip_forward=1
#net.ipv6.conf.all.disable_ipv6=1
#net.ipv6.conf.default.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf

    sudo touch /etc/.sysctlok
  fi
}

function fstab0 {
  if ! [ -f /etc/.fstabok ]; then
echo -e "
# Temp to ram!
tmpfs /tmp tmpfs defaults 0 0
tmpfs /var/tmp tmpfs defaults 0 0" | sudo tee -a /etc/fstab

    sudo touch /etc/.fstabok
  fi
}

function browsers0 {
  if ! [ -f /etc/.browserok ]; then
    # Brave
    echo "Instalando Brave Browser..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install brave-browser -y
    echo "Brave Browser instalado com sucesso!"
    
    # Google Chrome
    # wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    # sudo dpkg -i ./google-chrome*.deb; sudo rm google-chrome*.deb
    
    # # Microsoft Edge
    # wget https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_135.0.3179.54-1_amd64.deb
    # sudo dpkg -i microsoft-edge-stable_135.0.3179.54-1_amd64.deb; sudo rm microsoft-edge*.deb

    # Firefox
    # sudo install -d -m 0755 /etc/apt/keyrings &&
    # wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null &&
    # gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}' &&
    # echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null &&

  echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla &&

    sudo apt update; sudo apt install firefox -y

    sudo touch /etc/.browserok
  fi
}

function dwservice0 {
  wget https://www.dwservice.net/download/dwagent_x86.sh -O ~/dwagent_x86.sh
  chmod +x dwagent_x86.sh
}

function ADDCJoin0 {
  sudo pam-auth-update --enable mkhomedir
}

function flatpak0 {
  sudo apt install flatpak plasma-discover-backend-flatpak -y &&
  clear
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo &&
  clear
}

# function appsflat0 {
#   flatpak install com.anydesk.Anydesk \
#   us.zoom.Zoom \
#   com.thincast.client \
#   org.remmina.Remmina \
#   com.usebottles.bottles \
#   org.mozilla.Thunderbird \
#   com.ktechpit.whatsie \
#   com.github.tchx84.Flatseal \
#   uno.platform.uno-calculator \
#   io.missioncenter.MissionCenter \
#   org.kde.kpat \
#   net.codelogistics.webapps --noninteractive -y
#   clear
# }

function appsflat0 {
  # Instala MissionCenter via Flatpak
  flatpak install flathub io.missioncenter.MissionCenter --noninteractive -y

  # Baixa e instala Steam .deb
  echo "Instalando Steam..."
  wget -qO /tmp/steam.deb https://repo.steampowered.com/steam/archive/precise/steam_latest.deb
  sudo gdebi -n /tmp/steam.deb
  rm /tmp/steam.deb

  # Baixa e instala Discord .deb
  echo "Instalando Discord..."
  wget -qO /tmp/discord.deb https://discord.com/api/download?platform=linux&format=deb
  sudo gdebi -n /tmp/discord.deb
  rm /tmp/discord.deb

  clear
  echo "Instalação concluída!"
}

function onlyoffice0 {
  if ! [ -f /etc/.officeok ]; then
    mkdir -p ~/.gnupg
    gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
    chmod 644 /tmp/onlyoffice.gpg; sudo chown root:root /tmp/onlyoffice.gpg; sudo mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg

    echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee -a /etc/apt/sources.list.d/onlyoffice.list

    sudo apt update

    # no message since will not install ttf-mscore-fonts
    #message1

    sudo apt install onlyoffice-desktopeditors --no-install-recommends -y

    wget https://cs.linuxuniverse.com.br/public.php/dav/files/JTZj9ZKRHCSJSJE/?accept=zip -O mscorefonts.zip
    sudo mkdir -p /usr/share/fonts/All
    sudo unzip mscorefonts.zip -d /usr/share/fonts/All
    rm mscorefonts.zip
    fc-cache --force

    sudo touch /etc/.officeok
  fi
}

function wine0 {
  echo "deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_$(lsb_release -r | awk '{print $2}') ./" | sudo tee /etc/apt/sources.list.d/wine-obs.list
  wget -qO- "https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_$(lsb_release -r | awk '{print $2}')/Release.key" | sudo tee /etc/apt/trusted.gpg.d/winehq.asc
  sudo apt update
  sudo apt install -y wine-stable winetricks
}

function pathwine0 {
NEW_PATH="/opt/wine-stable/bin"

# Check if the path is already in the file
if grep -q "PATH=" /etc/environment; then
    # Append the new path to the existing PATH variable
    sudo sed -i "/^PATH=/ s|$|:$NEW_PATH|" /etc/environment
else
    # Add a new PATH variable if it doesn't exist
    echo "PATH=\"$NEW_PATH\"" | sudo tee -a /etc/environment
fi
}

function yaml0 {
  sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
}

function message0 {
  dialog --title "Informacao" --msgbox "A seguir sera perguntado se deseja instalar o suporte a certificado Token A3 nos navegadores.\n\nApenas pressione ENTER para confirmar." 10 40
  clear
}

function message2 {
  clear
  echo ""; echo""
  echo "INSTALACAO CONCLUIDA!"
  echo ""
  echo "O SISTEMA SERA REINICIADO EM 5 segundos."
  echo ""; echo ""
  sleep 5
}

function warning0 {
  clear
  echo -e "\e[1;31m###############################################################\e[0m"
  echo -e "\e[1;31mPARABÉNS, É EXATAMENTE ASSIM QUE EU GANHO ACESSO FÁCIL AO SEU COMPUTADOR!\e[0m"
  echo -e "\e[1;33mNUNCA COPIE E COLE COISAS NO SEU TERMINAL SEM CHECAR, SEU PATETA.\e[0m"
  echo -e "\e[1;36mATENÇÃO:\e[0m Use scripts apenas de fontes confiáveis."
  echo -e "\e[1;36mATENÇÃO:\e[0m Entenda o que cada comando faz antes de executar."
  echo -e "\e[1;36mATENÇÃO:\e[0m Sempre faça backup dos seus dados importantes."
  echo -e "\e[1;31m###############################################################\e[0m"
  echo ""

  while true; do
    read -rp $'\e[1;32mDigite "ENTENDI" para continuar: \e[0m' resposta
    if [[ "${resposta^^}" == "ENTENDI" ]]; then
      break
    else
      echo -e "\e[1;31mVocê precisa digitar exatamente \e[1;33mENTENDI\e[1;31m para prosseguir.\e[0m"
    fi
  done
  clear
}


function warning1 {
  clear
  echo -e "\e[1;33m###############################################################\e[0m"
  echo -e "\e[1;36mATENÇÃO: Este script foi baseado no script original do projeto SuitIT®.\e[0m"
  echo ""
  echo -e "\e[1;37mPrincipais diferenças e adaptações para o usuário final:\e[0m"
  echo "- Removemos ferramentas avançadas como compiladores, virtualização e monitoramento, focando no essencial."
  echo "- Substituímos o Google Chrome pelo navegador Brave, que prioriza privacidade e segurança."
  echo "- Simplificamos a lista de pacotes para acelerar a instalação e evitar programas desnecessários."
  echo "- Comentários explicativos foram adicionados para facilitar o entendimento."
  echo ""
  echo -e "\e[1;31mIMPORTANTE: Sempre revise e entenda cada comando antes de executar scripts no seu computador.\e[0m"
  echo -e "\e[1;31mNUNCA cole comandos aleatórios no terminal sem verificar a fonte!\e[0m"
  echo -e "\e[1;33m###############################################################\e[0m"
  echo ""
}


# ======================================================================================================================================================== #

warning0
warning1
root_check0
welcome0
useless0
update0
token0
bashconf0
timezone0
sysctl0
fstab0
browsers0
dwservice0
ADDCJoin0
flatpak0
appsflat0
# onlyoffice0
wine0
pathwine0
yaml0
message2

sudo reboot

exit 1
