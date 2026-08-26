#!/usr/bin/env bash
set -Eeuo pipefail

edition="${IMAGINE_EDITION:?Missing IMAGINE_EDITION}"
distribution="${IMAGINE_DISTRO:?Missing IMAGINE_DISTRO}"
asset_dir=/tmp/imigane-assets
config_dir=/tmp/imigane-config

echo imagineos > /etc/hostname
printf '127.0.0.1 localhost\n127.0.1.1 imagineos\n::1 localhost ip6-localhost ip6-loopback\n' > /etc/hosts
apt-get update
packages=(systemd-sysv dbus sudo locales udev network-manager network-manager-gnome live-boot live-config live-config-systemd user-setup plymouth plymouth-themes grub-pc-bin calamares polkitd pkexec xorg xserver-xorg-video-all fonts-dejavu fonts-noto-core pipewire wireplumber pavucontrol curl wget git ca-certificates gnupg rsync sassc file-roller p7zip-full gparted udisks2 parted kpartx util-linux lvm2 cryptsetup e2fsprogs dosfstools btrfs-progs ntfs-3g exfatprogs xfsprogs efibootmgr os-prober zstd desktop-base adwaita-icon-theme xfce4 xfce4-goodies lightdm light-locker lightdm-gtk-greeter thunar mousepad picom)
if [[ "$distribution" == ubuntu ]]; then
  packages+=(linux-image-generic linux-firmware grub-efi-amd64-bin firefox)
else
  packages+=(linux-image-686-pae firmware-linux-free grub-efi-ia32-bin firefox-esr)
fi
apt-get install -y --no-install-recommends "${packages[@]}"
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

install -d /usr/share/imagineos /usr/share/backgrounds/imagineos /usr/share/icons/hicolor/256x256/apps
install -m 0644 "$asset_dir/logo.png" /usr/share/imagineos/logo.png
install -m 0644 "$asset_dir/logo.png" /usr/share/icons/hicolor/256x256/apps/imagineos.png
install -m 0644 "$asset_dir/wallpaper.png" /usr/share/backgrounds/imagineos/imagineos.png
cat > /usr/lib/os-release <<EOF
NAME="ImagineOS"
PRETTY_NAME="ImagineOS 1.0 Beta"
ID=imagineos
ID_LIKE="$distribution debian"
VERSION="1.0 Beta"
VERSION_ID="1.0"
HOME_URL="https://github.com/GroupDev-Web/ImiganeOS"
SUPPORT_URL="https://github.com/GroupDev-Web/ImiganeOS/issues"
BUG_REPORT_URL="https://github.com/GroupDev-Web/ImiganeOS/issues"
EOF
ln -sfn ../usr/lib/os-release /etc/os-release

install -d /usr/share/plymouth/themes/imagine
cp "$config_dir/plymouth/imagine.plymouth" "$config_dir/plymouth/imagine.script" /usr/share/plymouth/themes/imagine/
cp "$asset_dir/logo.png" "$asset_dir/xproductions.png" "$asset_dir/spinner-dot.png" /usr/share/plymouth/themes/imagine/
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/imagine/imagine.plymouth 150
update-alternatives --set default.plymouth /usr/share/plymouth/themes/imagine/imagine.plymouth
install -d /boot/grub/themes/imagine /etc/default/grub.d
cp "$config_dir/grub/theme.txt" /boot/grub/themes/imagine/theme.txt
cp "$asset_dir/logo.png" /boot/grub/themes/imagine/logo.png
cp "$asset_dir/wallpaper.png" /boot/grub/themes/imagine/background.png
cp "$asset_dir"/select_*.png /boot/grub/themes/imagine/
cat > /etc/default/grub.d/imagineos.cfg <<'EOF'
GRUB_DISTRIBUTOR="ImagineOS"
GRUB_THEME="/boot/grub/themes/imagine/theme.txt"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_GFXMODE=auto
EOF

install -d /etc/calamares/modules /usr/share/calamares/branding/imagineos
cp "$config_dir/calamares/settings.conf" /etc/calamares/settings.conf
cp "$config_dir/calamares/unpackfs.conf" /etc/calamares/modules/unpackfs.conf
cp "$config_dir/calamares/bootloader.conf" /etc/calamares/modules/bootloader.conf
cp "$config_dir/calamares/displaymanager.conf" /etc/calamares/modules/displaymanager.conf
cp "$config_dir/calamares/branding.desc" "$config_dir/calamares/show.qml" /usr/share/calamares/branding/imagineos/
cp "$asset_dir/logo.png" "$asset_dir/wallpaper.png" /usr/share/calamares/branding/imagineos/
install -d /usr/share/applications /etc/skel/Desktop
install -m 0755 "$config_dir/desktop/imagineos-installer.sh" /usr/local/bin/imagineos-installer
install -m 0755 "$config_dir/desktop/imagineos-install.desktop" /usr/share/applications/imagineos-install.desktop
install -m 0755 "$config_dir/desktop/imagineos-install.desktop" /etc/skel/Desktop/imagineos-install.desktop

theme_root=/usr/share/themes
icon_root=/usr/share/icons
work=/tmp/imagine-theme
rm -rf "$work" && mkdir -p "$work" "$theme_root" "$icon_root"
theme_name=Adwaita
icon_name=Adwaita
greeter=lightdm-gtk-greeter
clone() { git clone --depth 1 "$1" "$2"; }
copy_theme_dirs() { find "$1" -mindepth 1 -maxdepth 3 -type d \( -name gtk-3.0 -o -name xfwm4 \) -printf '%h\n' | sort -u | while read -r directory; do cp -a "$directory" "$theme_root/"; done; }
first_theme() { find "$theme_root" -mindepth 1 -maxdepth 1 -type d -iname "$1" -printf '%f\n' | head -n1; }

case "$edition" in
  win95)
    clone https://github.com/grassmunk/Chicago95.git "$work/Chicago95"
    cp -a "$work/Chicago95/Theme/Chicago95" "$theme_root/"
    cp -a "$work/Chicago95/Icons/Chicago95" "$icon_root/"
    theme_name=Chicago95; icon_name=Chicago95
    if [[ -d "$work/Chicago95/Lightdm/Chicago95" ]]; then
      if apt-cache show lightdm-webkit2-greeter >/dev/null 2>&1 && apt-get install -y --no-install-recommends lightdm-webkit2-greeter; then
        install -d /usr/share/lightdm-webkit/themes
        cp -a "$work/Chicago95/Lightdm/Chicago95" /usr/share/lightdm-webkit/themes/Chicago95
        greeter=lightdm-webkit2-greeter
        printf '[greeter]\nwebkit_theme=Chicago95\n' > /etc/lightdm/lightdm-webkit2-greeter.conf
      else
        echo 'lightdm-webkit2-greeter is unavailable; using the GTK greeter for the Windows 95 edition.'
      fi
    fi
    ;;
  winxp)
    clone https://github.com/rozniak/xfce-winxp-tc.git "$work/winxp"; copy_theme_dirs "$work/winxp"
    cp -a "$work/winxp/icons/luna" "$icon_root/Luna"
    theme_name=professional; icon_name=Luna
    ;;
  win7)
    clone https://github.com/xRUS47x/Aero-Glass-XFCE4.git "$work/aero"; copy_theme_dirs "$work/aero"
    theme_name="$(first_theme '*aero*')"; [[ -n "$theme_name" ]] || theme_name=Adwaita
    picom_conf="$(find "$work/aero" -name picom.conf -print -quit)"
    if [[ -n "$picom_conf" ]]; then
      install -m 0644 "$picom_conf" /etc/xdg/picom.conf
    fi
    ;;
  win10)
    clone https://github.com/B00merang-Project/Windows-10.git "$work/win10"; copy_theme_dirs "$work/win10"
    theme_name=win10
    ;;
  vista)
    clone https://github.com/x35gaming/revista.git "$work/revista"; copy_theme_dirs "$work/revista"
    theme_name="$(first_theme '*vista*')"; [[ -n "$theme_name" ]] || theme_name="$(first_theme '*revista*')"; [[ -n "$theme_name" ]] || theme_name=Adwaita
    ;;
  win11)
    clone https://github.com/yeyushengfan258/Win11-gtk-theme.git "$work/win11"
    install -d "$theme_root/Win11-Light/gtk-2.0" "$theme_root/Win11-Light/gtk-3.0" "$theme_root/Win11-Light/gtk-4.0" "$theme_root/Win11-Light/xfwm4"
    cp -a "$work/win11/src/gtk-2.0/." "$theme_root/Win11-Light/gtk-2.0/"
    cp -a "$work/win11/src/gtk/assets" "$theme_root/Win11-Light/gtk-3.0/"
    cp -a "$work/win11/src/gtk/assets" "$theme_root/Win11-Light/gtk-4.0/"
    cp -a "$work/win11/src/xfwm4/." "$theme_root/Win11-Light/xfwm4/"
    cp "$work/win11/src/gtk/3.0/gtk-Light.css" "$theme_root/Win11-Light/gtk-3.0/gtk.css"
    cp "$work/win11/src/gtk/4.0/gtk-Light.css" "$theme_root/Win11-Light/gtk-4.0/gtk.css"
    clone https://github.com/yeyushengfan258/Win11-icon-theme.git "$work/win11-icons"
    cp -a "$work/win11-icons/src" "$icon_root/Win11"
    theme_name="$(first_theme 'Win11*Light*')"; [[ -n "$theme_name" ]] || theme_name="$(first_theme 'Win11*')"; [[ -n "$theme_name" ]] || theme_name=Adwaita
    icon_name="$(find "$icon_root" -mindepth 1 -maxdepth 1 -type d -iname '*win11*' -printf '%f\n' | head -n1)"; [[ -n "$icon_name" ]] || icon_name=Adwaita
    ;;
esac

install -d /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?><channel name="xsettings" version="1.0"><property name="Net" type="empty"><property name="ThemeName" type="string" value="$theme_name"/><property name="IconThemeName" type="string" value="$icon_name"/></property></channel>
EOF
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="theme" type="string" value="$theme_name"/></property></channel>
EOF
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?><channel name="xfce4-desktop" version="1.0"><property name="backdrop" type="empty"><property name="screen0" type="empty"><property name="monitor0" type="empty"><property name="workspace0" type="empty"><property name="last-image" type="string" value="/usr/share/backgrounds/imagineos/imagineos.png"/><property name="image-style" type="int" value="5"/></property></property></property></property></channel>
EOF
install -d /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\nuser-session=xfce\ngreeter-session=%s\n' "$greeter" > /etc/lightdm/lightdm.conf.d/90-imagineos.conf
printf '[greeter]\nbackground=/usr/share/backgrounds/imagineos/imagineos.png\ntheme-name=%s\nicon-theme-name=%s\n' "$theme_name" "$icon_name" > /etc/lightdm/lightdm-gtk-greeter.conf
systemctl enable lightdm NetworkManager
update-initramfs -u -k all
apt-get clean
