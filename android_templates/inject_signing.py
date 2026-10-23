#!/usr/bin/env python3
"""Inject release signing into Flutter Android app (Groovy + Kotlin DSL).

Always ensures signingConfigs.release exists before referencing it.
"""
from pathlib import Path
import re
import sys

root = Path("android")
app = root / "app"
jks_dest = app / "foroshgah-yar.jks"

src = Path("android_templates/foroshgah-yar.jks")
if src.exists():
    jks_dest.write_bytes(src.read_bytes())
    print("keystore copied ->", jks_dest)
if not jks_dest.exists():
    print("ERROR: keystore missing", file=sys.stderr)
    sys.exit(1)

kp = root / "key.properties"
kp.write_text(
    "storePassword=foroshgah2024\n"
    "keyPassword=foroshgah2024\n"
    "keyAlias=foroshgah\n"
    "storeFile=foroshgah-yar.jks\n",
    encoding="utf-8",
)
print("key.properties written")

# ---------- Groovy build.gradle ----------
for gpath in list(app.glob("build.gradle")):
    g = gpath.read_text(encoding="utf-8")

    # Remove previous injections (idempotent)
    g = re.sub(
        r"\ndef keystoreProperties = new Properties\(\).*?(?=\nandroid \{)",
        "\n",
        g,
        flags=re.S,
    )
    # Remove existing signingConfigs blocks (simple nested braces)
    while True:
        m = re.search(r"\n\s*signingConfigs\s*\{", g)
        if not m:
            break
        start = m.start()
        i = m.end()
        depth = 1
        while i < len(g) and depth:
            if g[i] == "{":
                depth += 1
            elif g[i] == "}":
                depth -= 1
            i += 1
        g = g[:start] + "\n" + g[i:]

    g = re.sub(r"\n\s*signingConfig\s+signingConfigs\.\w+", "", g)

    loader = (
        "\ndef keystoreProperties = new Properties()\n"
        "def keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    if "android {" in g and "keystoreProperties" not in g:
        g = g.replace("android {", loader + "android {", 1)

    signing_block = (
        "\n    signingConfigs {\n"
        "        release {\n"
        "            keyAlias keystoreProperties['keyAlias']\n"
        "            keyPassword keystoreProperties['keyPassword']\n"
        "            storeFile file(\"${projectDir}/\" + keystoreProperties['storeFile'])\n"
        "            storePassword keystoreProperties['storePassword']\n"
        "        }\n"
        "    }\n"
    )

    if "buildTypes {" in g:
        g = g.replace("buildTypes {", signing_block + "\n    buildTypes {", 1)
    else:
        g = g.replace("android {", "android {" + signing_block, 1)

    # Point release buildType to signingConfigs.release (only under buildTypes)
    if "buildTypes {" in g:
        head, tail = g.split("buildTypes {", 1)
        if "signingConfigs.release" not in tail:
            tail = re.sub(
                r"(release\s*\{)",
                r"\1\n            signingConfig signingConfigs.release",
                tail,
                count=1,
            )
        g = head + "buildTypes {" + tail

    gpath.write_text(g, encoding="utf-8")
    print("groovy signing injected", gpath)
    txt = gpath.read_text(encoding="utf-8")
    if "signingConfigs {" not in txt or "signingConfigs.release" not in txt:
        print("ERROR: groovy inject incomplete", file=sys.stderr)
        print(txt)
        sys.exit(1)

# ---------- Kotlin DSL build.gradle.kts ----------
for gpath in list(app.glob("build.gradle.kts")):
    g = gpath.read_text(encoding="utf-8")

    # strip old loader
    g = re.sub(
        r"(?m)^import java\.util\.Properties\n",
        "",
        g,
    )
    g = re.sub(
        r"(?m)^import java\.io\.FileInputStream\n",
        "",
        g,
    )
    g = re.sub(
        r"\nval keystorePropertiesFile = rootProject\.file\(\"key\.properties\"\)\nval keystoreProperties = Properties\(\)\.apply \{.*?\n\}\n",
        "\n",
        g,
        flags=re.S,
    )

    while True:
        m = re.search(r"\n\s*signingConfigs\s*\{", g)
        if not m:
            break
        start = m.start()
        i = m.end()
        depth = 1
        while i < len(g) and depth:
            if g[i] == "{":
                depth += 1
            elif g[i] == "}":
                depth -= 1
            i += 1
        g = g[:start] + "\n" + g[i:]

    g = re.sub(r"\n\s*signingConfig\s*=\s*signingConfigs\.getByName\(\"[^\"]+\"\)", "", g)

    loader = (
        "import java.util.Properties\n"
        "import java.io.FileInputStream\n\n"
        "val keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "val keystoreProperties = Properties().apply {\n"
        "    if (keystorePropertiesFile.exists()) {\n"
        "        load(FileInputStream(keystorePropertiesFile))\n"
        "    }\n"
        "}\n\n"
    )
    g = loader + g.lstrip()

    signing_block = (
        "\n    signingConfigs {\n"
        "        create(\"release\") {\n"
        "            keyAlias = keystoreProperties[\"keyAlias\"] as String\n"
        "            keyPassword = keystoreProperties[\"keyPassword\"] as String\n"
        "            storeFile = file(project.projectDir.resolve(keystoreProperties[\"storeFile\"] as String))\n"
        "            storePassword = keystoreProperties[\"storePassword\"] as String\n"
        "        }\n"
        "    }\n"
    )
    if "buildTypes {" in g:
        g = g.replace("buildTypes {", signing_block + "\n    buildTypes {", 1)
    elif "android {" in g:
        g = g.replace("android {", "android {" + signing_block, 1)

    if "buildTypes {" in g:
        head, tail = g.split("buildTypes {", 1)
        if 'signingConfigs.getByName("release")' not in tail:
            if re.search(r'getByName\("release"\)\s*\{', tail):
                tail = re.sub(
                    r'(getByName\("release"\)\s*\{)',
                    r'\1\n            signingConfig = signingConfigs.getByName("release")',
                    tail,
                    count=1,
                )
            elif re.search(r'create\("release"\)\s*\{', tail):
                tail = re.sub(
                    r'(create\("release"\)\s*\{)',
                    r'\1\n            signingConfig = signingConfigs.getByName("release")',
                    tail,
                    count=1,
                )
        g = head + "buildTypes {" + tail

    gpath.write_text(g, encoding="utf-8")
    print("kts signing injected", gpath)

found = False
for gpath in list(app.glob("build.gradle*")):
    txt = gpath.read_text(encoding="utf-8")
    if "signingConfigs" in txt and (
        "signingConfigs.release" in txt or 'getByName("release")' in txt
    ):
        found = True
        print("OK signing present in", gpath)
if not found:
    print("ERROR: failed to inject signing", file=sys.stderr)
    sys.exit(1)
print("SIGNING READY")
