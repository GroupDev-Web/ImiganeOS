#!/usr/bin/env bash
set -Eeuo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
edition=""
architecture=""
version="${IMAGINE_VERSION:-1.0-beta}"

usage() {
  cat <<'USAGE'
Usage: sudo ./scripts/build.sh --edition win95|winxp|win7|win10|vista|win11 --arch amd64|i386
USAGE
}

while (($#)); do
  case "$1" in
    --edition) edition="${2:?Missing edition}"; shift 2 ;;
    --arch) architecture="${2:?Missing architecture}"; shift 2 ;;
    --version) version="${2:?Missing version}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

case "$edition" in win95|winxp|win7|win10|vista|win11) ;; *) usage; exit 2 ;; esac
case "$architecture" in amd64|i386) ;; *) usage; exit 2 ;; esac
if [[ "$EUID" -ne 0 ]]; then
  echo 'This script requires root because debootstrap and chroot need elevated privileges.' >&2
  exit 1
fi

case "$architecture" in
  amd64) distribution=ubuntu; suite=noble; mirror=http://archive.ubuntu.com/ubuntu; arch_label=x86_64; efi_target=x86_64-efi ;;
  i386) distribution=debian; suite=bookworm; mirror=http://deb.debian.org/debian; arch_label=x86; efi_target=i386-efi ;;
esac

job_name="${edition}-${arch_label}"
work_dir="$root_dir/work/$job_name"
chroot_dir="$work_dir/chroot"
iso_dir="$work_dir/iso"
asset_dir="$work_dir/assets"
dist_dir="$root_dir/dist"
iso_name="ImagineOS-${version}-${edition}-${arch_label}.iso"

cleanup() {
  for mountpoint in dev/pts dev proc sys run; do
    if mountpoint -q "$chroot_dir/$mountpoint"; then
      umount -lf "$chroot_dir/$mountpoint" || true
    fi
  done
}
trap cleanup EXIT

echo "Building ImagineOS $version: $edition / $arch_label ($distribution $suite)"
mkdir -p "$work_dir" "$iso_dir/live" "$iso_dir/boot/grub/themes/imagine" "$dist_dir"
"$root_dir/scripts/generate-assets.sh" "$asset_dir"

if [[ ! -e "$chroot_dir/etc/debian_version" ]]; then
  debootstrap --arch="$architecture" --variant=minbase "$suite" "$chroot_dir" "$mirror"
fi

if [[ "$distribution" == ubuntu ]]; then
  cat > "$chroot_dir/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu $suite main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $suite-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $suite-security main restricted universe multiverse
EOF
else
  cat > "$chroot_dir/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian $suite main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $suite-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $suite-security main contrib non-free non-free-firmware
EOF
fi

cp /etc/resolv.conf "$chroot_dir/etc/resolv.conf"
mount --bind /dev "$chroot_dir/dev"
mount --bind /dev/pts "$chroot_dir/dev/pts"
mount -t proc proc "$chroot_dir/proc"
mount -t sysfs sys "$chroot_dir/sys"
mount --bind /run "$chroot_dir/run"

install -d "$chroot_dir/tmp/imigane-assets" "$chroot_dir/tmp/imigane-config"
cp -a "$asset_dir/." "$chroot_dir/tmp/imigane-assets/"
cp -a "$root_dir/config/." "$chroot_dir/tmp/imigane-config/"
cp "$root_dir/scripts/customize-chroot.sh" "$chroot_dir/tmp/customize-chroot.sh"

chroot "$chroot_dir" /usr/bin/env \
  DEBIAN_FRONTEND=noninteractive \
  IMAGINE_EDITION="$edition" \
  IMAGINE_ARCH="$architecture" \
  IMAGINE_DISTRO="$distribution" \
  IMAGINE_VERSION="$version" \
  bash /tmp/customize-chroot.sh

kernel_file="$(find "$chroot_dir/boot" -maxdepth 1 -name 'vmlinuz-*' | sort -V | tail -n 1)"
initrd_file="$(find "$chroot_dir/boot" -maxdepth 1 -name 'initrd.img-*' | sort -V | tail -n 1)"
[[ -n "$kernel_file" && -n "$initrd_file" ]] || { echo 'Kernel or initramfs was not generated.' >&2; exit 1; }
cp "$kernel_file" "$iso_dir/live/vmlinuz"
cp "$initrd_file" "$iso_dir/live/initrd.img"

cleanup
rm -rf "$chroot_dir/tmp/imigane-assets" "$chroot_dir/tmp/imigane-config" "$chroot_dir/tmp/customize-chroot.sh"
rm -rf "$chroot_dir/var/lib/apt/lists"/* "$chroot_dir/var/cache/apt/archives"/*.deb

mksquashfs "$chroot_dir" "$iso_dir/live/filesystem.squashfs" -comp xz -b 1M -noappend
du -sx --block-size=1 "$chroot_dir" | cut -f1 > "$iso_dir/live/filesystem.size"
chroot "$chroot_dir" dpkg-query -W --showformat='${Package} ${Version}\n' > "$iso_dir/live/filesystem.manifest"

cp "$root_dir/config/grub/grub.cfg" "$iso_dir/boot/grub/grub.cfg"
cp "$root_dir/config/grub/theme.txt" "$iso_dir/boot/grub/themes/imagine/theme.txt"
cp "$asset_dir/logo.png" "$iso_dir/boot/grub/themes/imagine/logo.png"
cp "$asset_dir/wallpaper.png" "$iso_dir/boot/grub/themes/imagine/background.png"
cp "$asset_dir"/select_*.png "$iso_dir/boot/grub/themes/imagine/"
mkdir -p "$iso_dir/boot/grub/fonts"
font_source="$(find /usr/share/grub /usr/share/grub2 -name unicode.pf2 -print -quit 2>/dev/null || true)"
if [[ -z "$font_source" ]]; then
  echo 'GRUB Unicode font was not found; refusing to create an unbootable theme.' >&2
  exit 1
fi
cp "$font_source" "$iso_dir/boot/grub/fonts/unicode.pf2"

cat > "$iso_dir/.disk-info" <<EOF
ImagineOS $version $edition $arch_label — Brought to you by XProductions
EOF

grub-mkrescue \
  -o "$dist_dir/$iso_name" \
  --modules='normal part_msdos part_gpt fat iso9660 all_video gfxterm png font linux reboot halt search search_fs_file' \
  "$iso_dir" \
  -- -volid 'IMAGINE_OS'

(cd "$dist_dir" && sha256sum "$iso_name" > "$iso_name.sha256")
cat > "$dist_dir/ImagineOS-${version}-${edition}-${arch_label}.json" <<EOF
{"name":"ImagineOS","version":"$version","edition":"$edition","architecture":"$arch_label","base":"$distribution","suite":"$suite","iso":"$iso_name"}
EOF

echo "Finished: $dist_dir/$iso_name"
