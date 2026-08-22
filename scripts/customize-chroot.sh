#!/usr/bin/env bash
set -Eeuo pipefail

flavor="${IMIGANE_FLAVOR:?Missing IMIGANE_FLAVOR}"
architecture="${IMIGANE_ARCH:?Missing IMIGANE_ARCH}"
distribution="${IMIGANE_DISTRO:?Missing IMIGANE_DISTRO}"
version="${IMIGANE_VERSION:?Missing IMIGANE_VERSION}"
asset_dir=/tmp/imigane-assets
config_dir=/tmp/imigane-config

echo imiganeos > /etc/hostname
cat > /etc/hosts <<'EOF'
127.0.0.1 localhost
127.0.1.1 imiganeos
::1 localhost ip6-localhost ip6-loopback
EOF

apt-get update
base_packages=(
  systemd-sysv dbus sudo locales network-manager network-manager-gnome
  live-boot live-config live-config-systemd
  plymouth plymouth-themes grub-pc-bin
  calamares polkitd pkexec
  xorg xserver-xorg-video-all fonts-dejavu fonts-noto-core
  pipewire wireplumber pavucontrol
  curl wget ca-certificates gnupg
  file-roller p7zip-full gparted
  desktop-base adwaita-icon-theme
)

if [[ "$distribution" == ubuntu ]]; then
  base_packages+=(linux-image-generic linux-firmware grub-efi-amd64-bin firefox)
else
  base_packages+=(linux-image-686-pae firmware-linux-free grub-efi-ia32-bin firefox-esr)
fi

case "$flavor" in
  xfce) desktop_packages=(xfce4 xfce4-goodies lightdm lightdm-gtk-greeter thunar mousepad) ;;
  budgie) desktop_packages=(budgie-desktop lightdm lightdm-gtk-greeter nautilus gnome-control-center gnome-terminal) ;;
  cosmic)
    if [[ "$architecture" != amd64 || "$distribution" != ubuntu ]]; then
      echo 'COSMIC requires Ubuntu amd64.' >&2
      exit 2
    fi
    apt-get install -y --no-install-recommends ca-certificates curl gnupg
    install -d -m 0755 /etc/apt/keyrings
    pop_key_fingerprint=63C46DF0140D738961429F4E204DD8AEC33A7AFF
    curl --fail --show-error --location --retry 3 \
      "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${pop_key_fingerprint}" \
      | gpg --dearmor --yes --output /etc/apt/keyrings/pop-os.gpg
    echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/pop-os.gpg] http://apt.pop-os.org/release noble main' > /etc/apt/sources.list.d/pop-os.list
    apt-get update
    if ! apt-cache show cosmic-session >/dev/null 2>&1; then
      echo 'The Pop!_OS repository does not currently provide cosmic-session for Ubuntu noble.' >&2
      exit 1
    fi
    desktop_packages=(cosmic-session cosmic-comp cosmic-panel cosmic-settings cosmic-files cosmic-term cosmic-greeter)
    ;;
  *) echo "Unsupported desktop: $flavor" >&2; exit 2 ;;
esac

apt-get install -y --no-install-recommends "${base_packages[@]}" "${desktop_packages[@]}"

sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

for required_group in sudo audio video netdev plugdev; do
  if ! getent group "$required_group" >/dev/null; then
    groupadd --system "$required_group"
  fi
done
useradd --create-home --shell /bin/bash --groups sudo,audio,video,netdev,plugdev imigane
echo 'imigane:imigane' | chpasswd
echo 'imigane ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-imigane-live
chmod 0440 /etc/sudoers.d/90-imigane-live

install -d /usr/share/imiganeos /usr/share/backgrounds/imiganeos /usr/share/icons/hicolor/256x256/apps
install -m 0644 "$asset_dir/logo.png" /usr/share/imiganeos/logo.png
install -m 0644 "$asset_dir/logo.png" /usr/share/icons/hicolor/256x256/apps/imiganeos.png
install -m 0644 "$asset_dir/wallpaper.png" /usr/share/backgrounds/imiganeos/imiganeos.png

cat > /etc/os-release <<EOF
NAME="ImiganeOS"
PRETTY_NAME="ImiganeOS 1.0 Beta"
ID=imiganeos
ID_LIKE="$distribution debian"
VERSION="1.0 Beta"
VERSION_ID="1.0"
HOME_URL="https://github.com/GroupDev-Web/ImiganeOS"
SUPPORT_URL="https://github.com/GroupDev-Web/ImiganeOS/issues"
BUG_REPORT_URL="https://github.com/GroupDev-Web/ImiganeOS/issues"
EOF
ln -sf /etc/os-release /usr/lib/os-release

install -d /usr/share/plymouth/themes/imigane
cp "$config_dir/plymouth/imigane.plymouth" "$config_dir/plymouth/imigane.script" /usr/share/plymouth/themes/imigane/
cp "$asset_dir/logo.png" "$asset_dir/xproductions.png" "$asset_dir/spinner-dot.png" /usr/share/plymouth/themes/imigane/
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/imigane/imigane.plymouth 150
update-alternatives --set default.plymouth /usr/share/plymouth/themes/imigane/imigane.plymouth

install -d /boot/grub/themes/imigane /etc/default/grub.d
cp "$config_dir/grub/theme.txt" /boot/grub/themes/imigane/theme.txt
cp "$asset_dir/logo.png" /boot/grub/themes/imigane/logo.png
cp "$asset_dir/wallpaper.png" /boot/grub/themes/imigane/background.png
cp "$asset_dir"/select_*.png /boot/grub/themes/imigane/
cat > /etc/default/grub.d/imiganeos.cfg <<'EOF'
GRUB_DISTRIBUTOR="ImiganeOS"
GRUB_THEME="/boot/grub/themes/imigane/theme.txt"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_GFXMODE=auto
EOF

install -d /etc/calamares/modules /usr/share/calamares/branding/imiganeos
cp "$config_dir/calamares/settings.conf" /etc/calamares/settings.conf
cp "$config_dir/calamares/unpackfs.conf" /etc/calamares/modules/unpackfs.conf
cp "$config_dir/calamares/bootloader.conf" /etc/calamares/modules/bootloader.conf
cp "$config_dir/calamares/displaymanager.conf" /etc/calamares/modules/displaymanager.conf
cp "$config_dir/calamares/branding.desc" "$config_dir/calamares/show.qml" /usr/share/calamares/branding/imiganeos/
cp "$asset_dir/logo.png" "$asset_dir/wallpaper.png" /usr/share/calamares/branding/imiganeos/

install -d /usr/share/applications /etc/skel/Desktop /home/imigane/Desktop
install -m 0755 "$config_dir/desktop/imiganeos-install.desktop" /usr/share/applications/imiganeos-install.desktop
install -m 0755 "$config_dir/desktop/imiganeos-install.desktop" /etc/skel/Desktop/imiganeos-install.desktop
install -m 0755 "$config_dir/desktop/imiganeos-install.desktop" /home/imigane/Desktop/imiganeos-install.desktop
chown -R imigane:imigane /home/imigane

case "$flavor" in
  xfce)
    install -d /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
    cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/imiganeos/imiganeos.png"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
    desktop_session=xfce
    ;;
  budgie)
    install -d /etc/dconf/db/local.d
    cat > /etc/dconf/db/local.d/00-imiganeos <<'EOF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/imiganeos/imiganeos.png'
picture-uri-dark='file:///usr/share/backgrounds/imiganeos/imiganeos.png'
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
EOF
    if command -v dconf >/dev/null 2>&1; then dconf update; fi
    desktop_session=budgie-desktop
    ;;
  cosmic) desktop_session=cosmic ;;
esac

if [[ "$flavor" != cosmic ]]; then
  install -d /etc/lightdm/lightdm.conf.d
  cat > /etc/lightdm/lightdm.conf.d/90-imiganeos.conf <<EOF
[Seat:*]
autologin-user=imigane
autologin-user-timeout=0
user-session=$desktop_session
greeter-session=lightdm-gtk-greeter
EOF
  cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[greeter]
background=/usr/share/backgrounds/imiganeos/imiganeos.png
theme-name=Adwaita-dark
icon-theme-name=Adwaita
EOF
  systemctl enable lightdm
else
  systemctl enable cosmic-greeter
fi

systemctl enable NetworkManager
update-initramfs -u -k all
apt-get clean
