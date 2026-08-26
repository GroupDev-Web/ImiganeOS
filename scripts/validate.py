#!/usr/bin/env python3
"""Fast structural checks for the ImagineOS release configuration."""
from pathlib import Path
import re, sys, xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
required = [".github/workflows/build.yml", "scripts/build.sh", "scripts/customize-chroot.sh",
            "branding/logo.svg", "branding/xproductions.svg", "branding/wallpaper.svg",
            "config/plymouth/imagine.script", "config/grub/grub.cfg",
            "config/calamares/branding.desc", "config/desktop/imagineos-installer.sh"]
errors = [f"Missing required file: {p}" for p in required if not (ROOT / p).is_file()]
for asset in (ROOT / "branding").glob("*.svg"):
    try: ET.parse(asset)
    except ET.ParseError as exc: errors.append(f"Invalid SVG {asset.relative_to(ROOT)}: {exc}")

workflow = (ROOT / ".github/workflows/build.yml").read_text()
entries = re.findall(r"edition:\s*(win95|winxp|win7|win10|vista|win11),\s*arch:\s*(amd64|i386)", workflow)
expected = {(edition, arch) for edition in ("win95", "winxp", "win7", "win10", "vista", "win11") for arch in ("amd64", "i386")}
if set(entries) != expected: errors.append(f"Build matrix mismatch: expected 12 targets, got {sorted(set(entries))}")

customize = (ROOT / "scripts/customize-chroot.sh").read_text()
for source in ("grassmunk/Chicago95", "rozniak/xfce-winxp-tc", "xRUS47x/Aero-Glass-XFCE4",
               "B00merang-Project/Windows-10", "x35gaming/revista", "yeyushengfan258/Win11-gtk-theme"):
    if source not in customize: errors.append(f"Missing edition theme source: {source}")
if "policykit-1" in customize: errors.append("Use polkitd and pkexec, not policykit-1")
for package in ("udisks2", "parted", "kpartx", "e2fsprogs", "dosfstools"):
    if package not in customize: errors.append(f"Installer requires {package}")
if 'NAME="ImagineOS"' not in customize: errors.append("OS identity was not renamed to ImagineOS")

plymouth = (ROOT / "config/plymouth/imagine.script").read_text()
if "xproductions.png" not in plymouth or "spinner.dot" not in plymouth: errors.append("Plymouth branding is incomplete")
if errors:
    print("\n".join(errors), file=sys.stderr); raise SystemExit(1)
print(f"Validated {len(required)} files and all {len(entries)} Windows-style build targets.")
