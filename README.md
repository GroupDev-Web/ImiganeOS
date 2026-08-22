# ImiganeOS Beta

ImiganeOS is a desktop operating system from XProductions, built as a bootable live ISO with an integrated Calamares installer.

| Edition | Architecture | Foundation | Firmware |
| --- | --- | --- | --- |
| Budgie | x86_64 | Ubuntu 24.04 LTS | BIOS + UEFI |
| XFCE | x86_64 | Ubuntu 24.04 LTS | BIOS + UEFI |
| COSMIC | x86_64 | Ubuntu 24.04 LTS + Pop!_OS packages | BIOS + UEFI |
| Budgie | x86 | Debian 12 | BIOS + 32-bit UEFI |
| XFCE | x86 | Debian 12 | BIOS + 32-bit UEFI |

COSMIC is intentionally unavailable for x86. Ubuntu no longer provides a complete 32-bit distribution, and Debian 13 removed its i386 kernel, so x86 editions use Debian 12 instead.

## Building

GitHub Actions builds all five editions automatically on pushes to `main`, and can also be started from **Actions → Build ImiganeOS → Run workflow**. Each successful job uploads an individual ISO artifact containing its checksum and build metadata.

For a local build on an Ubuntu or Debian amd64 host:

```bash
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools rsync imagemagick librsvg2-bin
sudo ./scripts/build.sh --flavor xfce --arch amd64
sudo ./scripts/build.sh --flavor budgie --arch i386
```

The finished image and SHA256 checksum are written to `dist/`.

## Identity

- Name: ImiganeOS
- Version: 1.0 Beta
- Publisher: XProductions
- Live account: `imigane`, with password `imigane`
- Installer: branded Calamares desktop shortcut
- Boot branding: custom GRUB theme and animated Plymouth splash

COSMIC uses System76's signed Pop!_OS package repository. Its build deliberately fails if the real COSMIC session cannot be installed; it never substitutes another desktop.
