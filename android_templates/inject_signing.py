#!/usr/bin/env python3
"""Inject release signing into Flutter Android app (Groovy + Kotlin DSL)."""
from pathlib import Path
import re
import sys

root = Path("android")
app = root / "app"
jks_dest = app / "foroshgah-yar.jks"

# Ensure keystore present
src = Path("android_templates/foroshgah-yar.jks")
if src.exists():
    jks_dest.write_bytes(src.read_bytes())
    print("keystore copied ->", jks_dest)
if not jks_dest.exists():
    print("ERROR: keystore missing", file=sys.stderr)
    sys.exit(1)

# key.properties at android/ (rootProject.file)
kp = root / "key.properties"
kp.write_text(
    "storePassword=foroshgah2024\n"
    "keyPassword=foroshgah2024\n"
    "keyAlias=foroshgah\n"
    "storeFile=foroshgah-yar.jks\n",
    encoding="utf-8",
)
print("key.properties:", kp.read_text().strip())

# ---- Groovy ----
for gpath in list(app.glob("build.gradle")):
    g = gpath.read_text(encoding="utf-8")
    # strip previous broken injection
    g = re.sub(r"\ndef keystoreProperties = new Properties\(\).*?(\nandroid \{)", r"\1", g, flags=re.S)
    loader = (
        "\ndef keystoreProperties = new Properties()\n"
        "def keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    if "android {" in g:
        g = g.replace("android {", loader + "android {", 1)
    if "signingConfigs" not in g:
        signing = (
            "\n    signingConfigs {\n"
            "        release {\n"
            "            keyAlias keystoreProperties['keyAlias']\n"
            "            keyPassword keystoreProperties['keyPassword']\n"
            "            storeFile file(keystoreProperties['storeFile'])\n"
            "            storePassword keystoreProperties['storePassword']\n"
            "        }\n"
            "    }\n"
        )
        if "buildTypes {" in g:
            g = g.replace("buildTypes {", signing + "\n    buildTypes {", 1)
        else:
            g = g.replace("android {", "android {" + signing, 1)
    # ensure release uses signingConfigs.release
    if "signingConfig signingConfigs.release" not in g:
        # remove any previous signingConfig line in release block then add
        g = re.sub(r"\n\s*signingConfig\s+[^\n]+", "", g)
        g = re.sub(
            r"(release\s*\{)",
            r"\1\n            signingConfig signingConfigs.release",
            g,
            count=1,
        )
    gpath.write_text(g, encoding="utf-8")
    print("groovy signing injected", gpath)

# ---- Kotlin DSL ----
for gpath in list(app.glob("build.gradle.kts")):
    g = gpath.read_text(encoding="utf-8")
    if "keystoreProperties" not in g:
        loader = (
            "\nimport java.util.Properties\n"
            "import java.io.FileInputStream\n\n"
            "val keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
            "val keystoreProperties = Properties().apply {\n"
            "    if (keystorePropertiesFile.exists()) {\n"
            "        load(FileInputStream(keystorePropertiesFile))\n"
            "    }\n"
            "}\n\n"
        )
        g = loader + g
    if "signingConfigs" not in g:
        signing = (
            "\n    signingConfigs {\n"
            "        create(\"release\") {\n"
            "            keyAlias = keystoreProperties[\"keyAlias\"] as String\n"
            "            keyPassword = keystoreProperties[\"keyPassword\"] as String\n"
            "            storeFile = file(keystoreProperties[\"storeFile\"] as String)\n"
            "            storePassword = keystoreProperties[\"storePassword\"] as String\n"
            "        }\n"
            "    }\n"
        )
        if "buildTypes {" in g:
            g = g.replace("buildTypes {", signing + "\n    buildTypes {", 1)
        elif "android {" in g:
            g = g.replace("android {", "android {" + signing, 1)
    if 'signingConfig = signingConfigs.getByName("release")' not in g:
        g = re.sub(r"\n\s*signingConfig\s*=\s*[^\n]+", "", g)
        g = re.sub(
            r'(getByName\("release"\)\s*\{)',
            r'\1\n            signingConfig = signingConfigs.getByName("release")',
            g,
            count=1,
        )
        # also try create("release") style
        if 'signingConfig = signingConfigs.getByName("release")' not in g:
            g = re.sub(
                r'(create\("release"\)\s*\{)',
                r'\1\n            signingConfig = signingConfigs.getByName("release")',
                g,
                count=1,
            )
    gpath.write_text(g, encoding="utf-8")
    print("kts signing injected", gpath)

# Final check
found = False
for gpath in list(app.glob("build.gradle*")):
    txt = gpath.read_text(encoding="utf-8")
    if "signingConfig" in txt and "release" in txt:
        found = True
        print("OK signing present in", gpath)
if not found:
    print("ERROR: failed to inject signing", file=sys.stderr)
    sys.exit(1)
print("SIGNING READY")
