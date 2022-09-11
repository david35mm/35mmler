#!/bin/sh

#--
# ISC License
#
# Copyright (c) 2022 David Andrés Ramírez Salomón <david35mm@disroot.org>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#++

main_menu() {
  while true; do
    cat << END
--------------------------------------
    David Salomon's GNU/Linux tool
--------------------------------------

  1) Install iwd and configure networking
  2) Configure the package manager
  3) Install the X11 Display Server
  4) Clone David's GitHub repository
  5) Install fonts, themes, icons & wallpapers
  6) Install utils and/or software collection
  7) Beautify!
  8) Delete unnecessary remaining files

  X) Exit

END
    printf '%b' "Please enter your choice: "
    read -r choice < /dev/tty
    clear
    case $choice in
      1) conf_network ;;
      2) conf_pkg_manager ;;
      3) install_xorg ;;
      4) clone_dotfiles ;;
      5) install_fti ;;
      6) utils_menu ;;
      7) pretty_pdm ;;
      8) delete_trash ;;
      x | X) exit ;;
      *) invalid ;;
    esac
  done
}

conf_network() {
  printf '%b\n' "Installling iwd"
  [ "$DISTRO" -eq 1 ] && pkg_install iwd systemd-networkd systemd-resolved \
    && cat <<END | tee fedora_run_after_reboot.sh && chmod 700 fedora_run_after_reboot.sh
#!/bin/sh

doas rpm -e --allmatches --nodeps $(dnf list installed | grep NetworkManager | cut -d'.' -f1) && doas dnf remove ModemManager wpa_supplicant
END
  [ "$DISTRO" -eq 2 ] && pkg_install iwd
  clear
  printf '%b\n' "Configuring wired and wireless networks with systemd-networkd"
  [ -e /etc/systemd/network/ ] || doas mkdir /etc/systemd/network/
  cat << END | doas tee /etc/systemd/network/20-wired.network && clear
[Match]
Name=en*

[Network]
DHCP=yes
IPv6PrivacyExtensions=true

[Route]
Gateway=_dhcp4
InitialCongestionWindow=30
InitialAdvertisedReceiveWindow=30

[DHCPv4]
Anonymize=true
RouteMetric=10

[IPv6AcceptRA]
RouteMetric=10
END
  cat << END | doas tee /etc/systemd/network/25-wireless.network && clear
[Match]
Name=wl*

[Network]
DHCP=yes
IPv6PrivacyExtensions=true
IgnoreCarrierLoss=3s

[Route]
Gateway=_dhcp4
InitialCongestionWindow=30
InitialAdvertisedReceiveWindow=30

[DHCPv4]
Anonymize=true
RouteMetric=20

[IPv6AcceptRA]
RouteMetric=20
END
  for file in /etc/systemd/network/2?-wired.network; do
    [ -e "$file" ] \
      && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m Wired and wireless networks were configured" \
      || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Something happened while configuring wired and wireless networks"
  done
  sleep 2.5
  clear
  printf '%b\n' "Setting Quad9 as primary DNS and Cloudflare as secondary with systemd-resolved"
  [ -e /etc/systemd/resolved.conf ] \
    && doas mv -vb /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
  cat << END | doas tee /etc/systemd/resolved.conf && clear \
    && doas ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf \
    && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m systemd-resolved has been configured successfully" \
    || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Something happened while writing systemd-resolved config"
[Resolve]
DNS=9.9.9.9#dns.quad9.net
FallbackDNS=1.1.1.2#security.cloudflare-dns.com
DNSOverTLS=yes
DNSSEC=allow-downgrade
Domains=~.
END
  sleep 2.5
  clear
  printf '%b\n' "Writing iwd settings at \033[0;34m\033[4m/etc/iwd/main.conf\033[0m"
  [ -e /etc/iwd/ ] || doas mkdir /etc/iwd/
  cat << END | doas tee /etc/iwd/main.conf && clear \
    && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m iwd setting were successfully written" \
    || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Something happened while writing the \033[0;34m\033[4m/etc/iwd/main.conf\033[0m file"
[General]
EnableNetworkConfiguration=false

[Network]
EnableIPv6=true
NameResolvingService=systemd

[Scan]
DisablePeriodicScan=false
END
  sleep 2.5
  clear
  printf '%b\n' "Enabling systemd services to be started in next boot"
  [ "$DISTRO" -eq 1 ] && doas systemctl disable ModemManager NetworkManager wpa_supplicant
  doas systemctl enable iwd systemd-networkd systemd-resolved
  clear
}

conf_pkg_manager() {
  if [ "$DISTRO" -eq 1 ]; then
    printf '%b\n' "Type your password to write a new DNF settings file"
    [ -e /etc/dnf/dnf.conf ] && doas mv -vb /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
    cat << END | doas tee /etc/dnf/dnf.conf && clear \
      && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m Settings written at \033[0;34m\033[4m/etc/dnf/dnf.conf\033[0m" \
      || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m The settings could not be written at \033[0;34m\033[4m/etc/dnf/dnf.conf\033[0m"
[main]
best=True
check_config_file_age=False
clean_requirements_on_remove=True
color=always
defaultyes=True
deltarpm=True
diskspacecheck=False
fastestmirror=True
gpgcheck=True
install_weak_deps=False
installonly_limit=2
keepcache=False
max_parallel_downloads=10
metadata_expire=259200
metadata_timer_sync=0
obsoletes=True
protect_running_kernel=False
skip_if_unavailable=True
throttle=0
zchunk=True
END
    sleep 2.5
    clear
    printf '%b\n' "Creating common aliases for DNF"
    doas dnf alias add cc='\clean all'
    doas dnf alias add if='info'
    doas dnf alias add in='install'
    doas dnf alias add lr='repolist'
    doas dnf alias add lu='list updates'
    doas dnf alias add ref='makecache'
    doas dnf alias add rm='remove'
    doas dnf alias add se='search'
    doas dnf alias add up='upgrade'
    doas dnf alias add wp='provides'
    clear
  elif [ "$DISTRO" -eq 2 ]; then
    printf '%b\n' "Type your password to write a new pacman settings file"
    [ -e /etc/pacman.conf ] && doas mv -vb /etc/pacman.conf /etc/pacman.conf.bak
    cat << END | doas tee /etc/pacman.conf && clear \
      && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m Settings written at \033[0;34m\033[4m/etc/pacman.conf\033[0m" \
      || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m The settings could not be written at \033[0;34m\033[4m/etc/pacman.conf\033[0m"
[options]
#CacheDir    = /var/cache/pacman/pkg/
#CleanMethod = KeepInstalled
#DBPath      = /var/lib/pacman/
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
#LogFile     = /var/log/pacman.log
#RootDir     = /
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
Architecture = auto
HoldPkg     = pacman glibc

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnoreGroup =
#IgnorePkg   =

#NoExtract   =
#NoUpgrade   =

#CheckSpace
#NoProgressBar
#UseSyslog
Color
ILoveCandy
ParallelDownloads = 10
VerbosePkgLists

#RemoteFileSigLevel = Required
LocalFileSigLevel = Optional
SigLevel    = Required DatabaseOptional
END
    sleep 2.5
    clear
    printf '%b\n' "Adding repos to pacman settings file"
    cat << END | doas tee -a /etc/pacman.conf && clear \
      && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m Repos added to \033[0;34m\033[4m/etc/pacman.conf\033[0m" \
      || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Repos could not be added to \033[0;34m\033[4m/etc/pacman.conf\033[0m"

# Arch Repos
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

#[multilib]
#Include = /etc/pacman.d/mirrorlist
END
    sleep 2.5
    clear
    printf '%b\n' "Installing Chaotic-AUR repo"
    doas pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    doas pacman-key --lsign-key FBA220DFC880C036
    doas pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    cat << END | doas tee -a /etc/pacman.conf && clear \
      && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m Chaotic-AUR repo added to \033[0;34m\033[4m/etc/pacman.conf\033[0m" \
      || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Failed trying to add Chaotic-AUR repo to \033[0;34m\033[4m/etc/pacman.conf\033[0m"

# Chaotic AUR
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
END
    sleep 2.5
    clear
    pkg_install pacman-contrib
    clear
  fi
}

install_xorg() {
  printf '%b\n' "Downloading the X11 Display Server, PipeWire and lightdm Display Manager"
  [ "$DISTRO" -eq 1 ] && pkg_install libva-vdpau-driver libvdpau \
    libvdpau-va-gl mesa-vdpau-drivers vulkan-loader mesa-dri-drivers \
    mesa-filesystem mesa-libEGL mesa-libgbm mesa-libGL mesa-libglapi \
    mesa-libxatracker mesa-vulkan-drivers xorg-x11-drv-evdev \
    xorg-x11-drv-fbdev xorg-x11-drv-libinput xorg-x11-drv-vesa \
    xorg-x11-server-common xorg-x11-server-Xorg xorg-x11-server-Xwayland \
    xorg-x11-xauth xorg-x11-xinit xrdb pipewire pipewire-alsa \
    pipewire-jack-audio-connection-kit pipewire-libs pipewire-pulseaudio \
    pipewire-utils wireplumber lightdm-gtk
  [ "$DISTRO" -eq 2 ] && pkg_install libva-vdpau-driver libvdpau \
    libvdpau-va-gl mesa-vdpau vulkan-icd-loader mesa xf86-input-evdev \
    xf86-input-libinput xf86-video-fbdev xf86-video-vesa xorg-server \
    xorg-server-common xorg-xauth xorg-xinit xorg-xrdb xorg-xwayland pipewire \
    pipewire-alsa pipewire-jack pipewire-pulse wireplumber lightdm-gtk-greeter
  clear
  if dialog --default-button "yes" --yesno "Are you using an AMD graphics card?" 0 0; then
    clear
    printf '%b\n' "Installing AMD drivers (2D support), Vulkan (3D support) and Accelerated Video Decoding support"
    [ "$DISTRO" -eq 1 ] && pkg_install xorg-x11-drv-amdgpu
    [ "$DISTRO" -eq 2 ] && pkg_install amdvlk libva-mesa-driver xf86-video-amdgpu
  else
    clear
    printf '%b\n' "Installing Intel drivers (2D support), Vulkan (3D support) and Accelerated Video Decoding support"
    [ "$DISTRO" -eq 1 ] && pkg_install libva-intel-hybrid-driver \
      xorg-x11-drv-intel
    [ "$DISTRO" -eq 2 ] && pkg_install vulkan-intel intel-media-driver \
      libva-intel-driver xf86-video-intel
  fi
  clear
  printf '%b\n' "Enabling lightdm service and changing the default systemd target to 'graphical'"
  doas systemctl enable lightdm && doas systemctl set-default graphical.target \
    && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m lightdm will start automatically on boot from now on" \
    || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m lightdm could not be enabled"
  sleep 2.5
  clear
}

clone_dotfiles() {
  if dialog --colors --msgbox "\ZbDISCLAIMER:\Zn\nBe aware that by cloning
the repo some important files in your \Zu\Z4$HOME\Zn folder are going to
be renamed (as a backup)" 0 0 \
    --clear --no-label "Do it later" --yes-label "Proceed" \
    --colors --yesno "This script will create backups of the following
files and folders \Zb\Z3(if they exist)\Zn:\n.bashrc\n.config/\n.files/\n
LICENSE\n.profile\nREADME.md\n\nThe backup files will have
a \Zu\Z4.bak\Zn extension\n\nDo you wish to proceed?" 0 0; then
    clear
    [ -e .bashrc ] && mv -vb .bashrc .bashrc.bak
    [ -e .config ] && mv -vb .config/ .config.bak/
    [ -e .files ] && mv -vb .files/ .files.bak/
    [ -e LICENSE ] && mv -vb LICENSE LICENSE.bak
    [ -e .profile ] && mv -vb .profile .profile.bak
    [ -e README.md ] && mv -vb README.md README.md.bak
    clear
    git clone --bare https://github.com/david35mm/.files.git "$HOME"/.files \
      && /usr/bin/git --git-dir="$HOME"/.files/ --work-tree="$HOME" checkout \
      && /usr/bin/git --git-dir="$HOME"/.files/ --work-tree="$HOME" config --local status.showUntrackedFiles no \
      && sleep 4 && clear \
        && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m All files were written successfully at your \033[0;34m\033[4m$HOME\033[0m folder" \
        || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m The repo files could not be written at your \033[0;34m\033[4m$HOME\033[0m folder"
    sleep 2.5
    clear
  fi
}

install_fti() {
  [ -e fonts-themes ] && rm -vrf fonts-themes/
  git clone https://github.com/david35mm/fonts-themes.git
  dialog --colors --msgbox "Installing fonts, themes and icons" 0 0
  clear
  [ -e /usr/share/fonts ] || doas mkdir -v /usr/share/fonts
  [ -e /usr/share/icons ] || doas mkdir -v /usr/share/icons
  [ -e /usr/share/themes ] || doas mkdir -v /usr/share/themes
  [ "$DISTRO" -eq 1 ] && doas dnf copr enable david35mm/plata-theme \
    && doas dnf install plata-theme
  [ "$DISTRO" -eq 2 ] \
    && doas busybox tar -C /usr/share/themes -xvJf fonts-themes/themes.tar.xz
  doas busybox tar -C /usr/share/fonts -xvJf fonts-themes/fonts.tar.xz
  doas busybox tar -C /usr/share/icons -xvJf fonts-themes/icons.tar.xz
  rm -vrf fonts-themes/
  clear
  dialog --colors --yesno "Would you like to install the Deepin DE Wallpaper pack?" 0 0 \
    && pkg_install deepin-wallpapers
  clear
}

utils_menu() {
  while true; do
    cat << END
------------------------------------------------
    Install utils and/or software collection
------------------------------------------------

  1) Install base utils (alacritty, polkit, ntfs support, rofi)
  2) Install some extra utils (dunst, pavucontrol, pcmanfm-qt, udiskie, etc)

  R) Return to menu

END
    printf '%b' "Please enter your choice: "
    read -r choice < /dev/tty
    clear
    case $choice in
      1) get_base_utils ;;
      2) get_extra_utils ;;
      r | R) main_menu ;;
      *) invalid ;;
    esac
  done
}

get_base_utils() {
  [ "$DISTRO" -eq 1 ] && doas dnf copr enable david35mm/pamixer \
    && pkg_install alacritty brightnessctl busybox exa lxpolkit man-db \
      ntfs-3g pamixer rofi
  [ "$DISTRO" -eq 2 ] && pkg_install alacritty brightnessctl busybox exa \
    lxsession-gtk3 man-db ntfs-3g pamixer rofi
  clear
}

get_extra_utils() {
  pkg_install arandr dunst libnotify lxappearance lxqt-archiver pavucontrol \
    pcmanfm-qt picom qt5ct udiskie zsh
  clear
  grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment \
    || printf '%b\n' "QT_QPA_PLATFORMTHEME=qt5ct" | doas tee -a /etc/environment
  doas curl -fsSLo /root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
  doas usermod -s /bin/zsh root
  clear
}

pretty_pdm() {
  printf '%b\n' "Type your password to write a new lightdm settings file"
  [ -e /etc/lightdm/lightdm-gtk-greeter.conf ] \
    && doas mv -vb /etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf.bak
  cat << END | doas tee /etc/lightdm/lightdm-gtk-greeter.conf && clear \
    && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m New lightdm settings writen at \033[0;34m\033[4m/etc/lightdm/lightdm-gtk-greeter.conf\033[0m" \
    || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m The settings could not be written at \033[0;34m\033[4m/etc/lightdm/lightdm-gtk-greeter.conf\033[0m"
[greeter]
background=/usr/share/wallpapers/deepin/Scenery_in_Plateau_by_Arto_Marttinen.jpg
clock-format=%A, %B %d %I:%M %p
cursor-theme-name=Vimix-cursors
font-name=Roboto Nerd Font
icon-theme-name=Tela-circle-dark
theme-name=Plata-Noir-Compact
END
  sleep 2.5
  clear
}

delete_trash() {
  dialog --colors --msgbox "Deleting the following files from your
\Zu\Z4$HOME\Zn folder:\nLICENSE\nREADME.md" 0 0
  clear
  doas rm -vrf LICENSE README.md
  clear
}

invalid() {
  printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Invalid answer, Please try again"
  sleep 2.5
  clear
}

pkg_install() {
  [ "$DISTRO" -eq 1 ] && doas dnf install -y "$@"
  [ "$DISTRO" -eq 2 ] && doas pacman -S --needed --noconfirm "$@"
}

main() {
  clear
  VERSION_CONTROL=numbered
  export VERSION_CONTROL
  [ "$(whoami)" = root ] \
    && printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Do not run this script as the \033[0;31mroot\033[0m user\n" \
    && exit 1
  cd "$HOME" \
    && printf '%b\n' "\n\t\033[0;32m\033[1m●  Succeded! \033[0m Running from \033[0;34m\033[4m$(pwd)\033[0m" \
    || printf '%b\n' "\n\t\033[0;31m\033[1m●  Error! \033[0m Something went wrong when entering your \033[0;34m\033[4m$HOME\033[0m folder"
  sleep 2.5
  clear
  cat << END
-------------------------------------------------

    Welcome to David Salomon's GNU/Linux tool

    Revision 0.2.0

    Brought to you by david35mm
    https://github.com/david35mm/

-------------------------------------------------
END
  sleep 4
  clear
  printf '%b\n' "Installing script's minimal dependencies (dialog - git - opendoas)"
  command -v dnf > /dev/null && DISTRO=1 \
    && su -c 'dnf install -y busybox dialog git-core opendoas && printf "permit persist :wheel\n" > /etc/doas.conf'
  command -v pacman > /dev/null && DISTRO=2 \
    && su -c 'pacman -S --needed --noconfirm busybox dialog git opendoas && printf "permit persist :wheel\n" > /etc/doas.conf'
  readonly DISTRO
  clear
  main_menu
}

main "$@"
