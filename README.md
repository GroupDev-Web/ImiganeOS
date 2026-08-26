# ImagineOS Beta

ImagineOS is a Linux distribution from XProductions designed to recreate familiar Windows desktop eras. It boots as a live system and includes a branded Calamares installer.

## Editions

| Edition | Theme source | Login / lock styling |
| --- | --- | --- |
| Windows 95 | [Chicago95](https://github.com/grassmunk/Chicago95) | Chicago95 LightDM greeter |
| Windows XP | [xfce-winxp-tc](https://github.com/rozniak/xfce-winxp-tc) | Matching GTK LightDM theme |
| Windows Vista | [ReVista](https://github.com/x35gaming/revista) | Matching GTK LightDM theme |
| Windows 7 | [Aero Glass](https://github.com/xRUS47x/Aero-Glass-XFCE4) | Matching GTK LightDM theme |
| Windows 10 | [Windows 10 theme](https://www.xfce-look.org/p/1216281) / [maintained source](https://github.com/B00merang-Project/Windows-10) | Matching GTK LightDM theme |
| Windows 11 | [Win11 GTK](https://github.com/yeyushengfan258/Win11-gtk-theme) + [icons](https://github.com/yeyushengfan258/Win11-icon-theme) | Matching GTK LightDM theme |

Every edition uses the same lightweight desktop foundation internally. ImagineOS product pages and downloads identify the Windows experience, not the underlying desktop environment.

All six editions build for x86_64 on Ubuntu 24.04 LTS and x86 on Debian 12. Debian 12 is used for x86 because modern Ubuntu no longer provides a complete 32-bit desktop base.

## Building

GitHub Actions builds twelve ISO artifacts on pushes to `main`. A single edition or architecture can also be selected from **Actions → Build ImagineOS → Run workflow**.

```bash
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools rsync imagemagick librsvg2-bin
sudo ./scripts/build.sh --edition win95 --arch amd64
sudo ./scripts/build.sh --edition winxp --arch i386
```

Finished ISOs, checksums, and build metadata are written to `dist/`.

## Identity

- Name: ImagineOS
- Version: 1.0 Beta
- Publisher: XProductions
- Live account is created at boot by Debian live-config and is not copied as a permanent installer account
- Installer: Calamares
- Boot branding: custom GRUB and animated Plymouth screens

Windows names and visual assets remain the property of their respective owners. ImagineOS is not affiliated with or endorsed by Microsoft.
