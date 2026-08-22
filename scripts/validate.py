#!/usr/bin/env python3
"""Fast structural checks for the ImiganeOS release configuration."""

from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
required = [
    ".github/workflows/build.yml",
    "scripts/build.sh",
    "scripts/customize-chroot.sh",
    "branding/logo.svg",
    "branding/xproductions.svg",
    "branding/wallpaper.svg",
    "config/plymouth/imigane.script",
    "config/grub/grub.cfg",
    "config/calamares/branding.desc",
]

errors = []
for relative in required:
    if not (ROOT / relative).is_file():
        errors.append(f"Missing required file: {relative}")

for asset in (ROOT / "branding").glob("*.svg"):
    try:
        ET.parse(asset)
    except ET.ParseError as exc:
        errors.append(f"Invalid SVG {asset.relative_to(ROOT)}: {exc}")

workflow = (ROOT / ".github/workflows/build.yml").read_text(encoding="utf-8")
entries = re.findall(r"flavor:\s*(budgie|xfce|cosmic),\s*arch:\s*(amd64|i386)", workflow)
expected = {("budgie", "amd64"), ("xfce", "amd64"), ("cosmic", "amd64"), ("budgie", "i386"), ("xfce", "i386")}
if set(entries) != expected:
    errors.append(f"Build matrix mismatch: expected {sorted(expected)}, got {sorted(set(entries))}")

plymouth = (ROOT / "config/plymouth/imigane.script").read_text(encoding="utf-8")
if "xproductions.png" not in plymouth or "spinner.dot" not in plymouth:
    errors.append("Plymouth must include the XProductions image and animated loading circle")

build_script = (ROOT / "scripts/build.sh").read_text(encoding="utf-8")
if "i386) distribution=debian; suite=bookworm;" not in build_script:
    errors.append("The i386 build must use Debian 12 bookworm, the last Debian release with a 32-bit kernel")

customize_script = (ROOT / "scripts/customize-chroot.sh").read_text(encoding="utf-8")
if "policykit-1" in customize_script:
    errors.append("Use polkitd and pkexec directly instead of the retired policykit-1 transitional package")
if "apt.pop-os.org/release.key" in customize_script:
    errors.append("The removed Pop!_OS release.key URL must not be used")
if "groupadd --system" not in customize_script:
    errors.append("Required live-user groups must be created before calling useradd")
if "cat > /usr/lib/os-release <<EOF" not in customize_script:
    errors.append("Write the ImiganeOS identity to the canonical /usr/lib/os-release file")
if "ln -sf /etc/os-release /usr/lib/os-release" in customize_script:
    errors.append("Do not link os-release onto itself or create a circular /etc ↔ /usr/lib symlink")
if "ln -sfn ../usr/lib/os-release /etc/os-release" not in customize_script:
    errors.append("Keep /etc/os-release as a relative symlink to /usr/lib/os-release")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)

print(f"Validated {len(required)} required files, {len(entries)} build targets, and all SVG branding assets.")
