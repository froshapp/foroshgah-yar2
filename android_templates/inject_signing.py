from pathlib import Path
import re

root = Path("android")
app = root / "app"
# Ensure keystore is in android/app/
jks_src_candidates = [
    Path("android_templates/foroshgah-yar.jks"),
    app / "foroshgah-yar.jks",
]
jks_dest = app / "foroshgah-yar.jks"
for c in jks_src_candidates:
    if c.exists() and c.resolve() != jks_dest.resolve():
        jks_dest.write_bytes(c.read_bytes())
        print("copied keystore ->", jks_dest)
        break

if not jks_dest.exists():
    raise SystemExit("ERROR: keystore not found at android/app/foroshgah-yar.jks")

# key.properties at android/ (rootProject.file)
# storeFile path relative to android/app module
kp = root / "key.properties"
kp.write_text(
    "storePassword=foroshgah2024\n"
    "keyPassword=foroshgah2024\n"
    "keyAlias=foroshgah\n"
    "storeFile=foroshgah-yar.jks\n",
    encoding="utf-8",
)
print("key.properties written")
print(kp.read_text())

# ---- Groovy build.gradle ----
for gpath in app.glob("build.gradle"):
    g = gpath.read_text(encoding="utf-8")
    if "keystoreProperties" not in g:
        loader = (
            "\ndef keystoreProperties = new Properties()\n"
            "def keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        g = g.replace("android {", loader + "android {", 1)
    if "signingConfigs" not in g:
        signing = (
            "\n    signingConfigs {\n"
            "        release {\n"
            "            keyAlias keystoreProperties[\"keyAlias\"]\n"
            "            keyPassword keystoreProperties[\"keyPassword\"]\n"
            "            storeFile file(keystoreProperties[\"storeFile\"])\n"
            "            storePassword keystoreProperties[\"storePassword\"]\n"
            "        }\n"
            "    }\n"
        )
        if "buildTypes {" in g:
            g = g.replace("buildTypes {", signing + "\n    buildTypes {", 1)
        else:
            g = g.replace("android {", "android {" + signing, 1)
    if "signingConfig signingConfigs.release" not in g:
        g = re.sub(
            r"(release\s*\{)",
            r"\1\n            signingConfig signingConfigs.release",
            g,
            count=1,
        )
    gpath.write_text(g, encoding="utf-8")
    print("groovy signing ok", gpath)

# ---- Kotlin DSL build.gradle.kts ----
for gpath in app.glob("build.gradle.kts"):
    g = gpath.read_text(encoding="utf-8")
    if "keystoreProperties" not in g:
        loader = (
            "\nimport java.util.Properties\n"
            "import java.io.FileInputStream\n\n"
            "val keystoreProperties = Properties()\n"
            "val keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        # insert before plugins or android
        if "plugins {" in g:
            g = loader + g
        else:
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
    if "signingConfig = signingConfigs.getByName(\"release\")" not in g and "signingConfigs.release" not in g:
        g = re.sub(
            r'(getByName\("release"\)\s*\{|release\s*\{)',
            lambda m: m.group(0) + '\n            signingConfig = signingConfigs.getByName("release")',
            g,
            count=1,
        )
    gpath.write_text(g, encoding="utf-8")
    print("kts signing ok", gpath)

print("SIGNING READY")
